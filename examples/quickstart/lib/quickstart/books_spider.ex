defmodule BooksToScrape do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://books.toscrape.com/"

  @impl Crawly.Spider
  def init() do
    [start_urls: ["https://books.toscrape.com/"]]
  end

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
