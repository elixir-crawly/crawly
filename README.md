# Crawly
[![Build Status](https://travis-ci.com/oltarasenko/crawly.svg?branch=master)](https://travis-ci.com/oltarasenko/crawly)
[![Coverage Status](https://coveralls.io/repos/github/oltarasenko/crawly/badge.svg?branch=coveralls)](https://coveralls.io/github/oltarasenko/crawly?branch=coveralls)
# Overview

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

# Requirements

1. Elixir  "~> 1.7"
2. Works on Linux, Windows, OS X and BSD

# Installation

1. Generate an new Elixir project: `mix new <project_name> --sup`
2. Add Crawly to you mix.exs file
    ```elixir
    def deps do
        [{:crawly, "~> 0.5.0"}]
    end
    ```
3. Fetch crawly: `mix deps.get`

# Quickstart

In this section we will show how to bootstrap the small project and to setup
Crawly for a proper data extraction.

1. Create a new Elixir project: `mix new crawly_example --sup`
2. Add Crawly to the dependencies (mix.exs file):
```elixir
defp deps do
    [
      {:crawly, "~> 0.5.0"}
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
By default Crawly does not require any configuration. But obviusely you will need
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
    Crawly.Pipelines.CSVEncoder
  ]
```


6. Start the Crawl:
 - `iex -S mix`
 - `Crawly.Engine.start_spider(EslSpider)`

7. Results can be seen in: `cat /tmp/EslSpider.jl`


# Documentation

Documentation is available online at
https://oltarasenko.github.io/crawly/#/  and in the docs directory.

# Tutorial

The crawly tutorial: https://oltarasenko.github.io/crawly/#/?id=crawly-tutorial


# Example projects

1. Blog crawler: https://github.com/oltarasenko/crawly-spider-example
2. E-commerce websites: https://github.com/oltarasenko/products-advisor
3. Car shops: https://github.com/oltarasenko/crawly-cars
