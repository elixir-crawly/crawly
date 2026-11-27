defmodule Crawly.E2E.BooksSpider do
  @moduledoc """
  The quickstart books spider (`examples/quickstart`), pointed at the local
  copy of books.toscrape.com served from `test/e2e/docker-compose.yml`.

  Used by `Crawly.E2E.BooksCrawlTest`. Runtime configuration:

    * `CRAWLY_E2E_BASE_URL` env var - site root (default `http://localhost:8080`)
    * `:e2e_output_dir` app env - folder for the `WriteToFile` pipeline
    * `:e2e_test_pid` app env - receives `{:e2e_page, url, status, items}` for
      every response and `{:e2e_spider_closed, crawl_id, reason}` on close
  """
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url() do
    "CRAWLY_E2E_BASE_URL"
    |> System.get_env("http://localhost:8080")
    |> String.trim_trailing("/")
  end

  @impl Crawly.Spider
  def init(), do: [start_urls: [base_url() <> "/index.html"]]

  @impl Crawly.Spider
  def override_settings() do
    [
      # Check every 15 s whether the crawl is done (default 60 s), so it stops
      # soon after the last page. The spider stops on the first check that
      # finds no queued requests and no new items.
      manager_operations_timeout: 15_000,
      # With 15 s checks this would stop a healthy crawl during the 10 s
      # pause each worker takes between requests.
      closespider_timeout: :disabled,
      closespider_itemcount: :disabled,
      concurrent_requests_per_domain: 8,
      middlewares: [
        Crawly.Middlewares.SameDomainFilter,
        Crawly.Middlewares.UniqueRequest,
        {Crawly.Middlewares.UserAgent, user_agents: ["Crawly E2E Bot"]}
      ],
      pipelines: [
        {Crawly.Pipelines.Validate, fields: [:url, :title, :price]},
        {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
        Crawly.Pipelines.JSONEncoder,
        {Crawly.Pipelines.WriteToFile,
         folder:
           Application.get_env(:crawly, :e2e_output_dir, System.tmp_dir!()),
         extension: "jl",
         include_timestamp: false}
      ],
      on_spider_closed_callback: fn _spider, crawl_id, reason ->
        notify({:e2e_spider_closed, crawl_id, reason})
      end
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)

    items =
      document
      |> Floki.find(".product_pod")
      |> Enum.map(fn x ->
        %{
          title:
            Floki.find(x, "h3 a") |> Floki.attribute("title") |> Floki.text(),
          price: Floki.find(x, ".product_price .price_color") |> Floki.text(),
          url: response.request_url
        }
      end)

    next_requests =
      document
      |> Floki.find(".next a")
      |> Floki.attribute("href")
      |> Enum.map(fn url ->
        Crawly.Utils.build_absolute_url(url, response.request_url)
        |> Crawly.Utils.request_from_url()
      end)

    notify(
      {:e2e_page, response.request_url, response.status_code, length(items)}
    )

    %Crawly.ParsedItem{items: items, requests: next_requests}
  end

  defp notify(message) do
    case Application.get_env(:crawly, :e2e_test_pid) do
      nil -> :ok
      pid -> send(pid, message)
    end
  end
end
