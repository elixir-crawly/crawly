defmodule SpiderTemplate do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://books.toscrape.com/"

  @impl Crawly.Spider
  def init() do
    [start_urls: ["https://books.toscrape.com/index.html"]]
  end

  @impl Crawly.Spider
  @doc """
     Extract items and requests to follow from the given response
  """
  def parse_item(response) do
    # Extract item field from the response here. Usually it's done this way:
    # {:ok, document} = Floki.parse_document(response.body)
    # item = %{
    #   title: document |> Floki.find("title") |> Floki.text(),
    #   url: response.request_url
    # }
    extracted_items = []

    # Extract requests to follow from the response. Don't forget that you should
    # supply request objects here. Usually it's done via
    #
    # urls = document |> Floki.find(".pagination a") |> Floki.attribute("href")
    # Don't forget that you need absolute urls
    # requests = Crawly.Utils.requests_from_urls(urls)

    next_requests = []
    %Crawly.ParsedItem{items: extracted_items, requests: next_requests}
  end
end
