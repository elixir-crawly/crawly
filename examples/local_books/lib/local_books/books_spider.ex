defmodule LocalBooks.BooksSpider do
  @moduledoc """
  The quickstart `BooksToScrape` spider, pointed at the local copy of
  books.toscrape.com from `test/e2e` instead of the real site.

  Set `BOOKS_BASE_URL` to crawl another copy (default `http://localhost:8080`).
  """
  use Crawly.Spider

  @impl Crawly.Spider
  def init() do
    [start_urls: [base_url() <> "/index.html"]]
  end

  @impl Crawly.Spider
  def base_url(), do: System.get_env("BOOKS_BASE_URL", "http://localhost:8080")

  @impl Crawly.Spider
  def parse_item(response) do
    # Parse response body to document
    {:ok, document} = Floki.parse_document(response.body)

    # Create item (for pages where items exists)
    items =
      document
      |> Floki.find(".product_pod")
      |> Enum.map(fn x ->
        %{
          title: Floki.find(x, "h3 a") |> Floki.attribute("title") |> Floki.text(),
          price: Floki.find(x, ".product_price .price_color") |> Floki.text(),
          url: response.request_url
        }
      end)

    next_requests =
      document
      |> Floki.find(".next a")
      |> Floki.attribute("href")
      |> Enum.map(fn url ->
        Crawly.Utils.build_absolute_url(url, response.request.url)
        |> Crawly.Utils.request_from_url()
      end)

    %{items: items, requests: next_requests}
  end
end
