defmodule Crawldis.Requestor do
  defstruct id: nil
  alias Crawldis.Requestor
  @behaviour Crawldis.Worker

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

  @impl Crawldis.Worker
  def via(id) do
    {:via, Horde.Registry, {Crawldis.Cluster.RequestorRegistry, id}}
  end

  @impl Crawldis.Worker
  def stop(id), do: Supervisor.stop(via(id))

end
