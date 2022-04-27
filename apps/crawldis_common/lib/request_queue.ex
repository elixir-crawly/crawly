defmodule CrawldisCommon.RequestQueue do
  alias CrawldisCommon.RequestQueue
  require Logger
  use GenServer
  @type item_states :: :unclaimed | :claimed
  @type queue_item :: {item_states(), Crawly.Request.t()}

  @type t:: %RequestQueue{
    crdt_pid: pid()
  }

  defstruct crdt_pid: nil
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

@impl true
  def init(_) do
    Logger.info("Request queue initializing")
    send(self(), :log)
    {:ok, crdt} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap)

    {:ok, %RequestQueue{crdt_pid: crdt}}
  end

  @spec add(Crawly.Request.t()):: :ok
  def add(request) do
    GenServer.cast(__MODULE__, {:add, request})
  end

  def claim_and_pop() do
    GenServer.call(__MODULE__, :claim_and_pop)
  end


  @impl true
  def handle_call(:claim_and_pop, _src, state) do
    queue = DeltaCrdt.to_map(state.crdt_pid)
    pop_res= Enum.find(queue, fn
      {_k, {:claimed, _req, %{claimed_datetime: dt}}}->  DateTime.diff(DateTime.utc_now(), dt) > 1
      _-> false
    end)
    popped_req = if pop_res do
      {popped_key , {_status, req, _meta}}  = pop_res
      DeltaCrdt.delete(state.crdt_pid, popped_key)
      req
    end
    claim_res = Enum.find(queue,fn
      {_k, {:unclaimed, _req, _}}->  true
      _-> false
    end)
    if claim_res do
      {to_claim_key , {_, claimed_req, meta}} = claim_res
      new_meta = Map.put(meta, :claimed_datetime, DateTime.utc_now())
      DeltaCrdt.put(state.crdt_pid, to_claim_key, {:claimed, claimed_req, new_meta })
    end

    {:reply, {:ok, popped_req}, state}
  end

  @impl true
  def handle_cast({:add, request}, %{crdt_pid: pid} =  state) do
    url = Map.get(request, :url)
      DeltaCrdt.put(pid, url, {:unclaimed, request})
      do_log(pid)
      {:noreply, state}
  end

  @impl true
  def handle_info(:log, %{crdt_pid: crdt_pid } = state) do
    do_log(crdt_pid)
    log_after()
    {:noreply, state}
  end


  defp do_log(pid) do
    queue = DeltaCrdt.to_map(pid)
    Logger.info("Queues", data: inspect(queue))
  end

  defp log_after do
    Process.send_after(self(), :log, 2000)
  end
end
