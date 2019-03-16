defmodule Mix.Tasks.Fetch do
  use Mix.Task

  @shortdoc "Fetches given link"
  def run(url) do
    Crawly.Application.start(:test, :test)
    Application.ensure_started(:sasl)
    Mix.shell().info([:green, "Starting a BlogEsl"])

    {:ok, pid} = Crawly.Shell.start_link()
    Crawly.Shell.get_response(url)
  end
end
