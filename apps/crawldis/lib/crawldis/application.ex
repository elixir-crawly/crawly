defmodule Crawldis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    IO.puts "starting crawldis"
    # topologies = [
    #   default: [
    #     strategy: Cluster.Strategy.Gossip
    #   ]
    # ]
    children = [
      Crawldis.Cluster,
      Crawldis.RequestQueue,
      Crawldis.Jobber,
      Crawldis.Connector
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crawldis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
