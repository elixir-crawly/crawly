defmodule Crawly.Bench.BenchSpider do
  @behaviour Crawly.Spider

  alias Crawly.Bench.BenchRouter
  alias Crawly.Utils

  @impl Crawly.Spider
  def base_url(), do: BenchRouter.build_url()

  @impl Crawly.Spider
  def init(), do: [start_urls: [BenchRouter.build_url(UUID.uuid1())]]

  @impl Crawly.Spider
  def parse_item(response) do
    links = String.split(response.body, "|", trim: true)

    %Crawly.ParsedItem{
      :requests => Utils.requests_from_urls(links),
      :items => [%{request_url: response.request_url, urls: links}]
    }
  end

  @impl Crawly.Spider
  def override_settings() do
    [
      closespider_itemcount: 100_000,
      pipelines: []
    ]
  end
end
