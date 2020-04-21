# Tutorial

---

In this tutorial, we’ll assume that Elixir is already installed on
your system. If that’s not the case, see Installation guide:
https://elixir-lang.org/install.html

We are going to scrape `https://www.homebase.co.uk`, a website that
contains products of different types.

This tutorial will walk you through these tasks:

1. Creating a new Crawly project.
2. Writing a spider to crawl a site and extract data.
3. Exporting the scraped data.

Crawly is written in Elixir. If you’re new to the language you might
want to start by getting an idea of what the language is like, to get
the most out of Crawly.

If you’re already familiar with other languages, and want to learn
Elixir quickly, the Elixir website
https://elixir-lang.org/learning.html is a good resource.

## Creating a project

Before you start crawling, you will have to set up a new Crawly
project. Enter a directory where you’d like to store your code and
run:

`mix new tutorial --sup`

This will create a tutorial directory with the following contents:

```bash
tutorial
├── README.md
├── lib
│   ├── tutorial
│   │   └── application.ex
│   └── tutorial.ex
├── mix.exs
└── test
    ├── test_helper.exs
    └── tutorial_test.exs

```

Switch to the project folder: `cd ./tutorial` and update the mix.exs
file with the following code:

```elixir
    defp deps do
      [
        {:crawly, "~> 0.9.0"},
        {:floki, "~> 0.26.0"}
      ]
    end
```

Now run `mix deps.get`

## Our first spider

Spiders are behaviours which you defined and that Crawly uses to
extract information from a given website. The spider must implement
the spider behaviour (it's required to implement `parse_item/1`, `init/0`,
`base_url/0` callbacks)

This is the code for our first spider. Save it in a file named
homebase.ex under the lib/tutorial/spiders directory of your project.

```elixir
defmodule Homebase do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.homebase.co.uk"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.homebase.co.uk/our-range/tools"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(_response) do
    %Crawly.ParsedItem{:items => [], :requests => []}
  end
end
```

As you can see, our Spider implements the Crawly.Spider behaviour and defines
some functions:

1. base_url: method which returns base_urls for the given Spider, used in
   order to filter out all irrelevant requests. In our case we don't want
   our crawler to follow links going to social media sites and other
   partner sites (which are not related to the homebase website themselves)

2. init(): must return a KW list which contains start_urls list which
   Crawler will begin to crawl from. Subsequent requests will be
   generated from these initial urls.

3. parse_item(): function which will be called to handle response
   downloaded by Crawly. It must return the `Crawly.ParsedItem` structure.

## How to run our spider

To put our spider to work, go to the project’s top level directory and
run:

1. `iex -S mix` - It will start the Elixir application which we have
   created, and will open interactive console.
2. Execute the following command in the opened Elixir console:
   `Crawly.Engine.start_spider(Homebase)`

You will get an output similar to this:

```
iex(2)> Crawly.Engine.start_spider(Homebase)

14:07:50.188 [debug] Starting the manager for Elixir.Homebase

14:07:50.188 [debug] Starting requests storage worker for Elixir.Homebase...

14:07:50.987 [debug] Started 4 workers for Elixir.Homebase
:ok

14:08:50.990 [info]  Current crawl speed is: 0 items/min
14:08:50.990 [info]  Stopping Homebase, itemcount timeout achieved
```

## What just happened under the hood?

Crawly schedules the Request objects returned by the init function of
the Spider. Upon receiving a response for each one, it instantiates
Response objects and calls the callback function associated with the
request passing the response as argument.

In our case we have not defined any data to be returned by the
`parse_item` callback. And the Crawly worker processes
(processes responsible for downloading requests) did not have any work
to do. And in cases like that, they will slow down progressively,
until the switch off (which happened because the Spider was not
extracting items fast enough).

And if you're wondering how to extract the data from the response,
please hold on. We're going to cover it in the next section.

## Extracting data

The best way to learn how to extract data with Crawly is trying the
selectors in Crawly shell.

1. Start the Elixir shell using `iex -S mix` command.
2. Now you can fetch a given HTTP response using the following
   command:
   `response = Crawly.fetch("https://www.homebase.co.uk/our-range/tools")`

You will see something like:

```
%HTTPoison.Response{
  body: "[response body here...]"
  headers: [
    {"Date", "Fri, 17 Apr 2020 10:34:35 GMT"},
    {"Content-Type", "text/html; charset=utf-8"},
    {"Transfer-Encoding", "chunked"},
    {"Connection", "keep-alive"},
    {"Set-Cookie",
     "__cfduid=d4c96698cfcfdfc9c1ef44ecb162b1cce1587119674; expires=Sun, 17-May-20 10:34:34 GMT; path=/; domain=.homebase.co.uk; HttpOnly; SameSite=Lax; Secure"},
    {"Cache-Control", "no-cache, no-store"},
    {"Pragma", "no-cache"},
    {"Expires", "-1"},
    {"Vary", "Accept-Encoding"},
    ...,
    {"cf-request-id", "02294d6d6f0000ffd430ad9200000001"}
  ], 
  request: %HTTPoison.Request{
    body: "",
    headers: [],
    method: :get,
    options: [],
    params: %{},
    url: "https://www.homebase.co.uk/our-range/tools"
  },
  request_url: "https://www.homebase.co.uk/our-range/tools",
  status_code: 200
}
```

Using the shell, you can try selecting elements using Floki with the
response. Let's say that we want to extract all product categories links from the
page above:

```
{:ok, document} = Floki.parse_document(response.body)
document |> Floki.find("section.wrapper") |> Floki.find("div.article-tiles.article-tiles--wide a") |> Floki.attribute("href")

["/our-range/tools/power-tools", "/our-range/tools/garage-storage",
 "/our-range/tools/hand-tools", "/our-range/tools/tool-storage",
 "/our-range/tools/ladders", "/our-range/tools/safety-equipment-and-workwear",
 "/our-range/tools/work-benches"]
```

The result of running the command above is a list of elements which
contain href attribute of links selected with
`a.category-block-heading__title` CSS selector. These URLs will be
used in order to feed Crawly with requests to follow.

In order to find the proper CSS selectors to use, you might find
useful opening the target page from the shell in your web browser. You
can use your browser developer tools to inspect the HTML and come up
with a selector.

Now let's navigate to one of the Homebase product pages and extract
data from it.

```
response = Crawly.fetch("https://www.homebase.co.uk/bosch-universalimpact-800-corded-hammer-drill_p494894")

```

Extract the `title` with:

```
{:ok, document} = Floki.parse_document(response.body)
document |> Floki.find(".page-title h1") |> Floki.text()
"Bosch UniversalImpact 800 Corded Hammer Drill"
```

Extract the `SKU` with:

```
document |> Floki.find(".product-header-heading span") |> Floki.text
"SKU:  494894"
```

Extract the `price` with:

```
document |> Floki.find(".price-value [itemprop=priceCurrency]") |> Floki.text
"£82"
```

## Extracting data in our spider

Let’s get back to our spider. Until now, it doesn’t extract any data,
just makes an `empty run`. Let’s integrate the extraction logic above
into our spider.

```elixir
defmodule Homebase do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.homebase.co.uk"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.homebase.co.uk/our-range/tools"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # Parse response body to document
    {:ok, document} = Floki.parse_document(response.body)

    # Extract product category URLs
    product_categories =
      document
      |> Floki.find("section.wrapper")
      |> Floki.find("div.article-tiles.article-tiles--wide a")
      |> Floki.attribute("href")

    # Extract individual product page URLs
    product_pages =
      document
      |> Floki.find("a.product-tile  ")
      |> Floki.attribute("href")

    urls = product_pages ++ product_categories

    # Convert URLs into Requests
    requests =
      urls
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    # Create item (for pages where items exists)
    item = %{
      title:
        document
        |> Floki.find(".page-title h1")
        |> Floki.text(),
      sku:
        document
        |> Floki.find(".product-header-heading span")
        |> Floki.text(),
      price:
        document
        |> Floki.find(".price-value [itemprop=priceCurrency]")
        |> Floki.text()
    }

    %Crawly.ParsedItem{:items => [item], :requests => requests}
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end

```

You will also need to tell Crawly where to store the scraped data. Create `config/config.exs` file with the following
contents:
```elixir
use Mix.Config

config :crawly,
  pipelines: [
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"}
  ]
```
The scraped data will now be stored in a CSV file under `/tmp` directory on your filesystem. The name of the file
will be the same as our spider name - in our case `Homebase.csv`.

If you restart iex and run this spider `Crawly.Engine.start_spider(Homebase)`, it will output messages like:

```
17:23:42.435 [debug] Dropping request: https://www.homebase.co.uk/bon-safety-rain-de-pro-superlight-weight-rainsuit-xxl_p275608, as it's already processed
17:23:42.435 [debug] Dropping request: https://www.homebase.co.uk/bon-safety-rain-de-pro-superlight-weight-rainsuit-l_p275605, as it's already processed
17:23:42.435 [debug] Dropping request: https://www.homebase.co.uk/bon-safety-rain-de-pro-superlight-weight-rainsuit-xl_p275607, as it's already processed
```

That's because Crawly filters out requests which it has already visited during the current run.

Go ahead and check the contents of your `/tmp/Homebase.csv` file. It should contain the scraped products like these:
```
{"title":"26 Inch Tool Chest (4 Drawer)","sku":"SKU:  555262","price":"£175"}
{"title":"26 Inch Tool Chest (10 Drawer)","sku":"SKU:  555260","price":"£280"}
{"title":"Draper 26 Inch Tool Chest (8 Drawer)","sku":"SKU:  518329","price":"£435"}
{"title":"Draper 26 Inch Tool Chest (6 Drawer)","sku":"SKU:  518327","price":"£405"}
{"title":"Draper 26 Inch Tool Chest (4 Drawer)","sku":"SKU:  518328","price":"£350"}
{"title":"Draper 26 Inch Tool Storage Chest (9 Drawer)","sku":"SKU:  518312","price":"£150"}
{"title":"Draper 26 Inch Tool Chest (5 Drawer)","sku":"SKU:  518311","price":"£139"}
{"title":"3 Tier Tool Trolley","sku":"SKU:  555311","price":"£90"}
{"title":"Draper 26 Inch Intermediate Tool Chest (2 Drawer)","sku":"SKU:  518309","price":"£80"}
{"title":"2 Tier Tool Trolley","sku":"SKU:  555310","price":"£70"}
```

## Next steps

This tutorial covered only the basics of Crawly, but there’s a lot of
other features not mentioned here.

You can continue from the section Basic concepts to know more about
the basic Crawly features.
