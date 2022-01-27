# Crawly

[![Crawly](https://circleci.com/gh/elixir-crawly/crawly.svg?style=svg)](https://app.circleci.com/pipelines/github/elixir-crawly)
[![Coverage Status](https://coveralls.io/repos/github/elixir-crawly/crawly/badge.svg?branch=master)](https://coveralls.io/github/elixir-crawly/crawly?branch=master)
[![Hex pm](http://img.shields.io/hexpm/v/crawly.svg?style=flat)](https://hex.pm/packages/crawly) [![hex.pm downloads](https://img.shields.io/hexpm/dt/crawly.svg?style=flat)](https://hex.pm/packages/crawly)

## Overview

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

## Requirements

1. Elixir "~> 1.10"
2. Works on Linux, Windows, OS X and BSD


## Quickstart

1. Add Crawly as a dependencies:
   ```elixir
   # mix.exs
   defp deps do
       [
         {:crawly, "~> 0.13.0"},
         {:floki, "~> 0.26.0"}
       ]
   end
   ```
2. Fetch dependencies: `$ mix deps.get`
3. Create a spider

    ```elixir
    # lib/crawly_example/books_to_scrape.ex
    defmodule BooksToScrape do
        use Crawly.Spider

        @impl Crawly.Spider
        def base_url(), do: "https://books.toscrape.com/"

        @impl Crawly.Spider
        def init(), do: [start_urls: ["https://books.toscrape.com/"]]

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
    ```

4. Configure Crawly
   - By default, Crawly does not require any configuration. But obviously you will need a configuration for fine tuning the crawls:
   ```elixir
   # in config.exs
   config :crawly,
     closespider_timeout: 10,
     concurrent_requests_per_domain: 8,
     middlewares: [
       Crawly.Middlewares.DomainFilter,
       Crawly.Middlewares.UniqueRequest,
       {Crawly.Middlewares.UserAgent, user_agents: ["Crawly Bot"]}
     ],
     pipelines: [
       {Crawly.Pipelines.Validate, fields: [:url, :title]},
       {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
       Crawly.Pipelines.JSONEncoder,
       {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"}
     ]
   ```
5. Start the Crawl:
   - `$ iex -S mix`
   - `iex(1)> Crawly.Engine.start_spider(EslSpider)`
6. Results can be seen with: `$ cat /tmp/EslSpider.jl`

## Need more help?
I have decided to create a public telegram channel, so it's now possible to be connected, and it's possible to ask questions
and get answers faster!

Please join me on: https://t.me/crawlyelixir

## Browser rendering

Crawly can be configured in the way that all fetched pages will be browser rendered,
which can be very useful if you need to extract data from pages which has lots
of asynchronous elements (for example parts loaded by AJAX).

You can read more here:
- [Browser Rendering](https://hexdocs.pm/crawly/basic_concepts.html#browser-rendering)

## Experimental UI

The CrawlyUI project is an add-on that aims to provide an interface for managing and rapidly developing spiders.

Checkout the code from [GitHub](https://github.com/oltarasenko/crawly_ui) 
or try it online [CrawlyUIDemo](http://crawlyui.com)

See more at [Experimental UI](https://hexdocs.pm/crawly/experimental_ui.html#content)

## Documentation

- [API Reference](https://hexdocs.pm/crawly/api-reference.html#content)
- [Quickstart](https://hexdocs.pm/crawly/readme.html#quickstart)
- [Tutorial](https://hexdocs.pm/crawly/tutorial.html)

## Roadmap

1. [x] Pluggable HTTP client
2. [x] Retries support
3. [x] Cookies support
4. [x] XPath support - can be actually done with meeseeks
5. [ ] Project generators (spiders)
6. [ ] UI for jobs management

## Articles

1. Blog post on Erlang Solutions website: https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html
2. Blog post about using Crawly inside a machine learning project with Tensorflow (Tensorflex): https://www.erlang-solutions.com/blog/how-to-build-a-machine-learning-project-in-elixir.html
3. Web scraping with Crawly and Elixir. Browser rendering: https://medium.com/@oltarasenko/web-scraping-with-elixir-and-crawly-browser-rendering-afcaacf954e8
4. Web scraping with Elixir and Crawly. Extracting data behind authentication: https://oltarasenko.medium.com/web-scraping-with-elixir-and-crawly-extracting-data-behind-authentication-a52584e9cf13
5. [What is web scraping, and why you might want to use it?](https://oltarasenko.medium.com/what-is-web-scraping-and-why-you-might-want-to-use-it-a0e4b621f6d0?sk=3145cceff095523c88e72e3ddb456016)
6. [Using Elixir and Crawly for price monitoring](https://oltarasenko.medium.com/using-elixir-and-crawly-for-price-monitoring-7364d345fc64?sk=9788899eb8e1d1dd6614d022eda350e8)
7. [Building a Chrome-based fetcher for Crawly](https://oltarasenko.medium.com/building-a-chrome-based-fetcher-for-crawly-a779e9a8d9d0?sk=2dbb4d39cdf319f01d0fa7c05f9dc9ec)

## Example projects

1. Blog crawler: https://github.com/oltarasenko/crawly-spider-example
2. E-commerce websites: https://github.com/oltarasenko/products-advisor
3. Car shops: https://github.com/oltarasenko/crawly-cars
4. JavaScript based website (Splash example): https://github.com/oltarasenko/autosites

## Contributors

We would gladly accept your contributions! 

## Documentation
Please find documentation on the [HexDocs](https://hexdocs.pm/crawly/)

## Production usages

Using Crawly on production? Please let us know about your case!
