defmodule Crawldis.Jobber do
  @moduledoc """
  Crawl job node-level manager for a cluster. Syncs state across nodes.any()

  The sole purpose of the Jobber is to cache job information and metadata, as well as to connect to the control plane.

  """
  alias Crawldis.{Syncer, Jobber}
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do

    get_pid = fn ->
      Jobber.Worker.get_state()
      |> Map.get(:crdt_pid)
    end
    children = [
      # add in request queue
      Jobber.Worker,
      {Syncer, [name: Jobber.Syncer, get_pid: get_pid]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # API

  @spec start_job(map()) :: {:ok, %Jobber.CrawlJob{}}
  def start_job(job), do: GenServer.call(Jobber.Worker, {:start_job, job})

  @spec list_jobs :: [%Jobber.CrawlJob{}]
  def list_jobs, do: GenServer.call(Jobber.Worker, :list_jobs)

  @spec get_job(binary()) :: %Jobber.CrawlJob{}
  def get_job(id) when is_binary(id), do: GenServer.call(Jobber.Worker, {:get_job, id})


  @spec stop_job(binary() | :all) :: :ok
  def stop_job(id_or_type), do: GenServer.cast(Jobber.Worker, {:stop_job, id_or_type})

end
