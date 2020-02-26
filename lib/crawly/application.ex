defmodule Crawly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # List all child processes to be supervised

    children = [
      worker(Crawly.Engine, []),
      supervisor(Crawly.EngineSup, []),
      {Crawly.DataStorage, []},
      {Crawly.RequestsStorage, []},
      {DynamicSupervisor,
       strategy: :one_for_one,
       name: Crawly.RequestsStorage.WorkersSup},
      {DynamicSupervisor,
       strategy: :one_for_one,
       name: Crawly.DataStorage.WorkersSup},
      {Plug.Cowboy,
       scheme: :http, 
       plug: Crawly.API.Router, 
       options: [port: Application.get_env(:crawly, :port, 4001)]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crawly.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
