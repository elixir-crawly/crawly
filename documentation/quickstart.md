# Quickstart

In this section we will show how to bootstrap a small project and to setup
Crawly for proper data extraction.

1. Create a new Elixir project: `mix new crawly_example --sup`
2. Add Crawly to the dependencies (mix.exs file):
```elixir
defp deps do
    [
      {:crawly, "~> 0.6.0"}
    ]
end
```
3. Fetch dependencies: `mix deps.get`
4. Define Crawling rules (Spider)
```elixir
cat > lib/crawly_example/esl_spider.ex << EOF
defmodule EslSpider do
  @behaviour Crawly.Spider
  alias Crawly.Utils

  @impl Crawly.Spider
  def base_url(), do: "https://www.erlang-solutions.com"

  @impl Crawly.Spider
  def init(), do: [start_urls: ["https://www.erlang-solutions.com/blog.html"]]

  @impl Crawly.Spider
  def parse_item(response) do
    hrefs = response.body |> Floki.find("a.more") |> Floki.attribute("href")

    requests =
      Utils.build_absolute_urls(hrefs, base_url())
      |> Utils.requests_from_urls()

    title = response.body |> Floki.find("article.blog_post h1") |> Floki.text()

    %{
      :requests => requests,
      :items => [%{title: title, url: response.request_url}]
    }
  end
end
EOF
```

5. Configure Crawly:
By default Crawly does not require any configuration. But obviously you will need
a configuration for fine tuning the Crawls:

```elixir
config :crawly,
  closespider_timeout: 10,
  concurrent_requests_per_domain: 8,
  follow_redirects: true,
  closespider_itemcount: 1000,
  output_format: "csv",
  item: [:title, :url],
  item_id: :title,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    Crawly.Middlewares.UserAgent
  ],
  pipelines: [
    Crawly.Pipelines.Validate,
    Crawly.Pipelines.DuplicatesFilter,
    Crawly.Pipelines.CSVEncoder,
    Crawly.Pipelines.WriteToFile
  ]
```


6. Start the Crawl:
 - `iex -S mix`
 - `Crawly.Engine.start_spider(EslSpider)`

7. Results can be seen in: `cat /tmp/EslSpider.csv`
