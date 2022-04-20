defmodule CrawldisWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CrawldisWeb.Telemetry,
      # Start the Endpoint (http/https)
      CrawldisWeb.Endpoint
      # Start a worker by calling: CrawldisWeb.Worker.start_link(arg)
      # {CrawldisWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CrawldisWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CrawldisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
