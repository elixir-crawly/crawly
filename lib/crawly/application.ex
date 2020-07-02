defmodule Crawly.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Crawly.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  defp children do
    import Supervisor.Spec, warn: false

    [
      worker(Crawly.Engine, []),
      supervisor(Crawly.EngineSup, []),
      {Crawly.DataStorage, []},
      {Crawly.RequestsStorage, []},
      {DynamicSupervisor,
       strategy: :one_for_one, name: Crawly.RequestsStorage.WorkersSup},
      {DynamicSupervisor,
       strategy: :one_for_one, name: Crawly.DataStorage.WorkersSup},
      {Plug.Cowboy,
       scheme: :http,
       plug: Crawly.API.Router,
       options: [port: Application.get_env(:crawly, :port, 4001)]}
      | bench()
    ]
  end

  defp bench do
    if Application.get_env(:crawly, :bench, []) do
      [
        {Plug.Adapters.Cowboy,
         scheme: :http,
         plug: Crawly.Bench.BenchRouter,
         options: [port: Application.get_env(:crawly, :benchmark_port, 8085)]}
      ]
    end
  end
end
