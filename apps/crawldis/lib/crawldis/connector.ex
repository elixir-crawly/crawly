defmodule Crawldis.Connector do
  @moduledoc "Conencts to the server"
  use Supervisor
  require Logger
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Crawldis.Connector.Socket,
      Crawldis.Connector.Worker,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
  def reconnect do
    Supervisor.stop(Crawldis.Connector)
  end
end
