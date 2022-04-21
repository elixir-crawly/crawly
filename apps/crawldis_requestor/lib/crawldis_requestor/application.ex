defmodule CrawldisRequestor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    children = [
      CrawldisRequestor,
      CrawldisCommon.ClusterSup,
      {Task, fn-> test_request() end},
    ]


    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CrawldisRequestor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp test_request() do
    :timer.sleep(2000)
    CrawldisRequestor.crawl("https://www.tzeyiing.com")
  end
end
