defmodule Crawly.Bench.BenchSpider do
  @behaviour Crawly.Spider

  alias Crawly.Bench.BenchRouter
  alias Crawly.Manager
  alias Crawly.Utils

  @impl Crawly.Spider
  def base_url(), do: BenchRouter.build_url()

  @impl Crawly.Spider
  def init(), do: [start_urls: [BenchRouter.build_url("asdf")]]

  @impl Crawly.Spider
  def parse_item(response) do
    links = String.split(response.body, "|", trim: true)
    Manager.performance_info("Elixir.#{__MODULE__}") # we need to add some delay before ask for info
    %Crawly.ParsedItem{
      :requests => Utils.requests_from_urls(links),
      :items => [%{request_url: response.request_url, urls: links}]
    }
  end

  @impl Crawly.Spider
  def override_settings() do
    [
      concurrent_requests_per_domain: 50,
      closespider_itemcount: 100_000,
      closespider_timeout: 50,
      pipelines: [
        {Crawly.Pipelines.CSVEncoder, fields: ~w(request_url urls)a},
        {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"}
      ]
    ]
  end
end
