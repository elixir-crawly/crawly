defmodule CrawldisPanel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      # CrawldisWeb.Telemetry,
      # Start the Endpoint (http/https)
      # CrawldisWeb.Endpoint,
      CrawldisPanel.Repo,
      # {Phoenix.PubSub, name: CrawldisWeb.PubSub}
      # Start a worker by calling: CrawldisWeb.Worker.start_link(arg)
      # {CrawldisWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CrawldisPanel.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
