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
├── config
│   └── config.exs
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
    def deps do
        [{:crawly, "~> 0.7.0"}]
    end
```

Now run `mix deps.get`

## Our first spider

Spiders are behaviours which you defined and that Crawly uses to
extract information from a given website. The spider must implement
the spider behaviour (it's required to implement `parse_item/1`, `init/0`,
`base_url/0` callbacks)

This is the code for our first spider. Save it in a file name
homebase.ex under the lib/tutorial/spiders directory of your project.

```elixir
defmodule Homebase do
  @behaviour Crawly.Spider

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

As you can see, our Spider implements the Spider behaviour and defines
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

1. iex -S mix - It will start the Elixir application which we have
   created, and will open interactive console
2. Execute the following command in the opened Elixir console:
   `Crawly.Engine.start_spider(Homebase)`

You will get an output similar to this:

```elixir
iex(2)> Crawly.Engine.start_spider(Homebase)

15:03:47.134 [info]  Starting the manager for Elixir.Homebase

=PROGRESS REPORT==== 23-May-2019::15:03:47 ===
         supervisor: {<0.415.0>,'Elixir.Crawly.ManagerSup'}
            started: [{pid,<0.416.0>},
                      {id,'Elixir.Homebase'},
                      {mfargs,
                          {'Elixir.DynamicSupervisor',start_link,
                              [[{strategy,one_for_one},
                                {name,'Elixir.Homebase'}]]}},
                      {restart_type,permanent},
                      {shutdown,infinity},
                      {child_type,supervisor}]

15:03:47.137 [debug] Starting requests storage worker for
Elixir.Homebase..

15:04:06.698 [debug] No work, increase backoff to 2400
15:04:06.699 [debug] No work, increase backoff to 4800
15:04:06.699 [debug] No work, increase backoff to 9600
15:04:07.973 [debug] No work, increase backoff to 19200
15:04:17.787 [info]  Stopping Homebase, itemcount timeout achieved
```

## What just happened under the hood?

Crawly schedules the Request objects returned by the init function of
the Spider. Upon receiving a response for each one, it instantiates
Response objects and calls the callback function associated with the
request passing the response as argument.

In our case we have not defined any data to be returned by the
`parse_item` callback. And in our the Crawly worker processes
(processes responsible for downloading requests) did not have work
to do. And in the cases like that, they will slow down progressively,
until the switch off (which happened because the Spider was not
extracting items fast enough).

And if you're wondering how to extract the data from the response,
please hold on. We're going to cover it in the next section.

## Extracting data

The best way to learn how to extract data with Crawly is trying the
selectors in Crawly shell.

1. Start the Elixir shell using `iex -S mix` command
2. Now you can fetch a given HTTP response using the following
   command:
   `{:ok, response} = Crawly.fetch("https://www.homebase.co.uk/our-range/tools")`

You will see something like:

```
{:ok,
 %HTTPoison.Response{
   body: "[response body here...]"
   headers: [
     {"Date", "Fri, 24 May 2019 02:37:26 GMT"},
     {"Content-Type", "text/html; charset=utf-8"},
     {"Transfer-Encoding", "chunked"},
     {"Connection", "keep-alive"},
     {"Cache-Control", "no-cache, no-store"},
     {"Pragma", "no-cache"},
     {"Expires", "-1"},
     {"Vary", "Accept-Encoding"},
     {"Set-Cookie", "Bunnings.Device=default; path=/"},
     {"Set-Cookie",
      "ASP.NET_SessionId=bcb2deqlapednir0lysulo1h; path=/; HttpOnly"},
     {"Set-Cookie", "Bunnings.Device=default; path=/"},
     {"Set-Cookie",
      "ASP.NET_SessionId=bcb2deqlapednir0lysulo1h; path=/; HttpOnly"},
     {"Set-Cookie", "Bunnings.UserType=RetailUser; path=/"},
     ....,
     {"Set-Cookie",
      "__AntiXsrfToken=fd198cd78d1b4826ba00c24c3af1ec56; path=/; HttpOnly"},
     {"Server", "cloudflare"},
     {"CF-RAY", "4dbbe33fae7e8b20-KBP"}
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
 }}
```

Using the shell, you can try selecting elements using Floki with the
response. Lets say that we want to extract all product categories links from the
page above:

```
response.body |> Floki.find("div.product-list-footer a") |>
Floki.attribute("href")

"/our-range/tools/power-tools/drills", "/our-range/tools/power-tools/saws",
 "/our-range/tools/power-tools/sanders",
 "/our-range/tools/power-tools/electric-screwdrivers",
 "/our-range/tools/power-tools/tools-accessories",
 "/our-range/tools/power-tools/routers-and-planers",
 "/our-range/tools/power-tools/multi-tools",
 "/our-range/tools/power-tools/impact-drivers-and-wrenches",
 "/our-range/tools/power-tools/air-compressors",
 "/our-range/tools/power-tools/angle-grinders",
 "/our-range/tools/power-tools/heat-guns",
 "/our-range/tools/power-tools/heavy-duty-construction-tools",
 "/our-range/tools/power-tools/welding" ...]
```

The result of running the command above is a list of elements which
contain href attribute of links selected with
`a.category-block-heading__title` css selector. These URLs will be
used in order to feed Crawly with requests to follow.

In order to find the proper CSS selectors to use, you might find
useful opening the target page from the shell in your web browser. You
can use your browser developer tools to inspect the HTML and come up
with a selector.

Now let's navigate to one of the Homebase product pages and extract
data from it.

```
{:ok, response} =
Crawly.fetch("https://www.homebase.co.uk/4-tier-heavy-duty-shelving-unit_p375180")

```

Extract the `title` with:

```
response.body |> Floki.find(".page-title h1") |> Floki.text()
"4 Tier Heavy Duty Shelving Unit"
```

Extract the `SKU` with:

```
response.body |> Floki.find(".product-header-heading span") |> Floki.text
"SKU:  375180"
```

Extract the `price` with:

```
response.body |> Floki.find(".price-value [itemprop=priceCurrency]") |> Floki.text
"£75"
```

## Extracting data in our spider

Let’s get back to our spider. Until now, it doesn’t extract any data,
just makes an `empty run`. Let’s integrate the extraction logic above
into our spider.

```elixir
defmodule Homebase do
  @behaviour Crawly.Spider

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
    # Extract product category URLs
    product_categories =
      response.body
      |> Floki.find("div.product-list-footer a")
      |> Floki.attribute("href")

    # Extract individual product page URLs
    product_pages =
      response.body
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
      title: response.body |> Floki.find(".page-title h1") |> Floki.text(),
      sku:
        response.body
        |> Floki.find(".product-header-heading span")
        |> Floki.text(),
      price:
        response.body
        |> Floki.find(".price-value [itemprop=priceCurrency]")
        |> Floki.text()
    }

    %Crawly.ParsedItem{:items => [item], :requests => requests}
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end

```

If you run this spider, it will output the extracted data with the log:

```
17:23:42.536 [debug] Scraped %{price: "£3.99", sku: "SKU:  486386", title: "Bon Safety EN20471 Hi viz Yellow Vest, size XL"}
17:23:43.432 [debug] Scraped %{price: "£3.99", sku: "SKU:  486384", title: "Bon Safety EN20471 Hi viz Yellow Vest, size L"}
17:23:42.389 [debug] Scraped %{price: "£5.25", sku: "SKU:  414464", title: "Toughbuilt 24in Wall Organizer"}
```

Also you will see messages like:

```
17:23:42.435 [debug] Dropping request: https://www.homebase.co.uk/bon-safety-rain-de-pro-superlight-weight-rainsuit-xxl_p275608, as it's already processed
17:23:42.435 [debug] Dropping request: https://www.homebase.co.uk/bon-safety-rain-de-pro-superlight-weight-rainsuit-l_p275605, as it's already processed
17:23:42.435 [debug] Dropping request: https://www.homebase.co.uk/bon-safety-rain-de-pro-superlight-weight-rainsuit-xl_p275607, as it's already processed
```

That's because Crawly filters out requests which it has already
visited during the current run.

## Where the data is stored afterwords?

You might wonder where is the resulting data is located by default?
Well the default location of the scraped data is under the /tmp
folder. This can be controlled by the `base_store_path` variable in
the Crawly configuration (`:crawly`, `:base_store_path`).

## Next steps

This tutorial covered only the basics of Crawly, but there’s a lot of
other features not mentioned here.

You can continue from the section Basic concepts to know more about
the basic Crawly features.
