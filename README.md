# Crawly

[![Build Status](https://travis-ci.com/oltarasenko/crawly.svg?branch=master)](https://travis-ci.com/oltarasenko/crawly)
[![Coverage Status](https://coveralls.io/repos/github/oltarasenko/crawly/badge.svg?branch=coveralls)](https://coveralls.io/github/oltarasenko/crawly?branch=coveralls)
[![Hex pm](http://img.shields.io/hexpm/v/crawly.svg?style=flat)](https://hex.pm/packages/crawly) [![hex.pm downloads](https://img.shields.io/hexpm/dt/crawly.svg?style=flat)](https://hex.pm/packages/crawly)

## Overview

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

## Requirements

1. Elixir "~> 1.7"
2. Works on Linux, Windows, OS X and BSD


## Quickstart

1. Add Crawly as a dependencies:
   ```elixir
   # mix.exs
   defp deps do
       [
         {:crawly, "~> 0.8.0"}
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
     closespider_itemcount: 1000,
     middlewares: [
       Crawly.Middlewares.DomainFilter,
       Crawly.Middlewares.UniqueRequest,
       Crawly.Middlewares.UserAgent
     ],
     pipelines: [
       {Crawly.Pipelines.Validate, fields: [:url, :title]},
       {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
       Crawly.Pipelines.JSONEncoder,
       {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"} # NEW IN 0.7.0
      ]
   ```
5. Start the Crawl:
   - `$ iex -S mix`
   - `iex(1)> Crawly.Engine.start_spider(EslSpider)`
6. Results can be seen with: `$ cat /tmp/EslSpider.csv`

## Browser rendering

Crawly can be configured in the way that all fetched pages will be browser rendered,
which can be very useful if you need to extract data from pages which has lots
of asynchronous elements (for example parts loaded by AJAX).

You can read more here:
- [Browser Rendering](https://hexdocs.pm/crawly/basic_concepts.html#browser-rendering)

## Documentation

- [API Reference](https://hexdocs.pm/crawly/api-reference.html#content)
- [Quickstart](https://hexdocs.pm/crawly/quickstart.html)
- [Tutorial](https://hexdocs.pm/crawly/tutorial.html)

## Roadmap

1. [x] Pluggable HTTP client
2. [x] Retries support
3. [ ] Cookies support
4. [ ] XPath support
5. [ ] Project generators (spiders)
6. [ ] UI for jobs management

## Articles

1. Blog post on Erlang Solutions website: https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html
2. Blog post about using Crawly inside a machine learning project with Tensorflow (Tensorflex): https://www.erlang-solutions.com/blog/how-to-build-a-machine-learning-project-in-elixir.html

## Example projects

1. Blog crawler: https://github.com/oltarasenko/crawly-spider-example
2. E-commerce websites: https://github.com/oltarasenko/products-advisor
3. Car shops: https://github.com/oltarasenko/crawly-cars

## Contributors

We would gladly accept your contributions! 

## Documentation
Please find documentation on the [HexDocs](https://hexdocs.pm/crawly/)
