defmodule CrawldisCommon.RequestQueue do
  alias CrawldisCommon.RequestQueue
  alias CrawldisCommon.RequestQueue.{Worker, Syncer}
  require Logger
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, [])
  end

  @impl true
  def init(_init_arg) do
    Logger.info("Request queue supervisor initializing")

    children = [
      Worker,
      Syncer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

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
  require Logger

  # API

  @spec add_request(Crawly.Request.t()) :: :ok
  def add_request(request) do
    GenServer.cast(Worker, {:add_request, request})
  end

  @spec claim_request() :: :ok
  def claim_request() do
    GenServer.cast(Worker, :claim_request)
  end

  @spec clear_requests() :: :ok
  def clear_requests() do
    GenServer.call(Worker, :clear_requests)
  end

  @spec pop_claimed_request() :: {:ok, Crawly.Request.t()}
  def pop_claimed_request() do
    GenServer.call(Worker, :pop_claimed_request)
  end

  @spec count_requests() :: integer()
  @spec count_requests(:all | item_status()) :: integer()
  def count_requests(filter \\ :all) do
    GenServer.call(Worker, {:count_requests, filter})
  end

  @spec list_requests() :: [%Crawly.Request{}]
  @spec list_requests(:all | item_status()) :: [%Crawly.Request{}]
  def list_requests(filter \\ :all) do
    GenServer.call(Worker, {:list_requests, filter})
  end

  @doc false
  @spec get_state :: %RequestQueue{}
  def get_state do
    GenServer.call(Worker, :state)
  end
end
