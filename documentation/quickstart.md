# Quickstart

---

Goals:

- Scrape the Erlang Solutions blog for articles, and scrape the article titles.
- Perform pagination to see more blog posts.

1. Add Crawly as a dependencies:
   ```elixir
   # mix.exs
   defp deps do
       [
         {:crawly, "~> 0.6.0"}
       ]
   end
   ```
2. Fetch dependencies: `$ mix deps.get`
3. Create a spider

   ```elixir
   # lib/crawly_example/esl_spider.ex
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
   ```

4. Configure Crawly
   - By default, Crawly does not require any configuration. But obviously you will need a configuration for fine tuning the crawls:
   ```elixir
   # in config.exs
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
5. Start the Crawl:
   - `$ iex -S mix`
   - `iex(1)> Crawly.Engine.start_spider(EslSpider)`
6. Results can be seen with: `$ cat /tmp/EslSpider.csv`
