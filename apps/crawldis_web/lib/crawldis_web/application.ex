defmodule CrawldisWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @impl true
  def start(_type, _args) do
    IO.puts("starting crawldisweb")
    env = Application.get_env(:crawldis_panel, :env)

    children =
      case env do
        :test ->
          [
            CrawldisWeb.Endpoint,
            {Phoenix.PubSub, name: CrawldisWeb.PubSub},
            CrawldisWeb.Presence
          ]

        _ ->
          [
            CrawldisWeb.Endpoint,
            {Phoenix.PubSub, name: CrawldisWeb.PubSub},
            CrawldisWeb.Presence,
            CrawldisWeb.Startup
          ]
      end

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
