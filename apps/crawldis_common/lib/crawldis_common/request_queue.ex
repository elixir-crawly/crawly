defmodule CrawldisCommon.RequestQueue do
  alias CrawldisCommon.RequestQueue
  require Logger
  use GenServer
  @type item_status :: :unclaimed | :claimed

  @type t :: %RequestQueue{
          crdt_pid: pid()
        }
  defmodule Meta do
    defstruct claimed_datetime: nil,
              request: nil,
              status: :unclaimed
  end

  @type queue_item :: %Meta{}
  defstruct crdt_pid: nil

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("Request queue initializing")
    {:ok, crdt} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap)

    {:ok, %RequestQueue{crdt_pid: crdt}}
  end

  @spec add_request(Crawly.Request.t()) :: :ok
  def add_request(request) do
    GenServer.cast(__MODULE__, {:add_request, request})
  end

  @spec claim_request() :: :ok
  def claim_request() do
    GenServer.cast(__MODULE__, :claim_request)
  end

  @spec clear_requests() :: :ok
  def clear_requests() do
    GenServer.call(__MODULE__, :clear_requests)
  end

  @spec pop_claimed_request() :: {:ok, Crawly.Request.t()}
  def pop_claimed_request() do
    GenServer.call(__MODULE__, :pop_claimed_request)
  end

  @spec count_requests() :: integer()
  @spec count_requests(:all | item_status()) :: integer()
  def count_requests(filter \\ :all) do
    GenServer.call(__MODULE__, {:count_requests, filter})
  end

  @spec list_requests() :: [%Crawly.Request{}]
  @spec list_requests(:all | item_status()) :: [%Crawly.Request{}]
  def list_requests(filter \\ :all) do
    GenServer.call(__MODULE__, {:list_requests, filter})
  end

  @impl true
  def handle_call(:clear_requests, _source, state) do
    keys = get_queue(state) |> Map.keys()
    DeltaCrdt.drop(state.crdt_pid, keys)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:count_requests, filter}, _source, state) do
    count =
      get_queue(state)
      |> Map.values()
      |> Enum.filter(fn
        _ when filter == :all -> true
        %{status: status} -> status == filter
      end)
      |> length()

    {:reply, count, state}
  end

  @impl true
  def handle_call({:list_requests, filter}, _source, state) do
    list = get_queue(state) |> Map.values()

    requests =
      list
      |> Enum.filter(fn
        _ when filter == :all -> true
        %{status: status} -> status == filter
      end)

    {:reply, requests, state}
  end

  @impl true
  def handle_call(:pop_claimed_request, _src, state) do
    queue = DeltaCrdt.to_map(state.crdt_pid)

    pop_res =
      Enum.find(queue, fn
        {_k, %{status: :claimed, claimed_datetime: dt}} ->
          DateTime.diff(DateTime.utc_now(), dt, :millisecond) >= 500

        _ ->
          false
      end)

    popped_req =
      if pop_res do
        {key, %{request: req}} = pop_res
        DeltaCrdt.delete(state.crdt_pid, key)
        req
      end

    {:reply, {:ok, popped_req}, state}
  end

  @impl true
  def handle_cast(:claim_request, state) do
    queue = DeltaCrdt.to_map(state.crdt_pid)

    claim_res =
      Enum.find(queue, fn
        {_k, %{status: :unclaimed}} -> true
        _ -> false
      end)

    if claim_res do
      {key, meta} = claim_res

      DeltaCrdt.put(state.crdt_pid, key, %{
        meta
        | status: :claimed,
          claimed_datetime: DateTime.utc_now()
      })
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_request, request}, %{crdt_pid: pid} = state) do
    url = Map.get(request, :url)
    DeltaCrdt.put(pid, url, %Meta{request: request})
    {:noreply, state}
  end

  defp get_queue(state) do
    DeltaCrdt.to_map(state.crdt_pid)
  end
end