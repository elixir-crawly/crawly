defmodule CrawldisCommon.Requestor do
  defstruct id: nil
  alias CrawldisCommon.Requestor
  @behaviour CrawldisCommon.Worker

  use Supervisor, restart: :transient

  def start_link(id) do
    Supervisor.start_link(__MODULE__, [], name: via(id))
  end

  @impl true
  def init(_init_arg) do
    children = [
      # add in request queue
      Requestor.Worker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @impl CrawldisCommon.Worker
  def via(id) do
    {:via, Horde.Registry, {CrawldisCommon.Cluster.RequestorRegistry, id}}
  end

  @impl CrawldisCommon.Worker
  def stop(id), do: Supervisor.stop(via(id))

end
