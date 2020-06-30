defmodule Crawly.Bench.BenchSpider do
  @behaviour Crawly.Spider

  alias Crawly.Request

  @url "http://localhost:8085/"

  @impl Crawly.Spider
  def base_url(), do: @url

  @impl Crawly.Spider
  def init(), do: [start_urls: ["http://localhost:8085/?num=0"]]

  @impl Crawly.Spider
  def parse_item(response) do
    new_url = @url <> "?num=" <> response.body
    %Crawly.ParsedItem{
      :requests => [%Request{url: new_url}],
      :items => [%{number: response.body, url: new_url}]
    }
  end

  @impl Crawly.Spider
  def override_settings() do
    [
      pipelines: [
        {Crawly.Pipelines.CSVEncoder, fields: ~w(number url)a},
        {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"},
      ]
    ]
  end
end
