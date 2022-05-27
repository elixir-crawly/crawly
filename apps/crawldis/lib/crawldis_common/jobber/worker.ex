defmodule Crawldis.Jobber.Worker do
  alias Crawldis.{Jobber, RequestQueue}
  alias Crawldis.Jobber.{CrawlJob}
  require Logger
  use GenServer

  @type t :: %__MODULE__{
          crdt_pid: pid()
        }
  defmodule JobMeta do
    defstruct id: nil
  end

  defstruct crdt_pid: nil

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, crdt} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap)
    {:ok, %__MODULE__{crdt_pid: crdt}}
  end


  # API

  @spec get_state :: %Jobber.Worker{}
  def get_state, do: GenServer.call(__MODULE__, :state)


  # Callbacks

  @impl true
  def handle_call(:state, _source, state) do
    {:reply, state, state}
  end


  @impl true
  def handle_call(:list_jobs, _source, state) do
    list = get_queue(state) |> Map.values()
    {:reply, list, state}
  end


  @impl true
  def handle_call({:get_job, id}, _source, %{crdt_pid: pid} = state) do
    job = DeltaCrdt.get(pid, id)
    {:reply, job, state}
  end


  @impl true
  def handle_call({:start_job, attrs}, _src, %{crdt_pid: pid} = state) do
    job =  struct(CrawlJob, attrs) |> Map.put(:id, UUID.uuid4())
    DeltaCrdt.put(pid, job.id, job )
    Logger.debug("Adding job: #{inspect(job)}")
    # add requests
    for url <-job.start_urls  do
      request = Crawldis.Utils.new_request(job, url)
      RequestQueue.add_request(request)
    end
    {:reply, {:ok, job}, state}
  end


  @impl true
  def handle_cast({:stop_job, id_or_type}, state) when is_binary(id_or_type) or id_or_type in [:all] do
    keys = if id_or_type == :all do
      get_queue(state) |> Map.keys()
    else
      [id_or_type]
    end
    DeltaCrdt.drop(state.crdt_pid, keys)
    RequestQueue.clear_requests_by_crawl_job_id(keys)
    {:noreply, state}
  end


  defp get_queue(state) do
    DeltaCrdt.to_map(state.crdt_pid)
  end
end
