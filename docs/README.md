# Crawly into
---

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

## Walk-through of an example spider

In order to show you what Crawly brings to the table, we’ll walk you
through an example of a Crawly spider using the simplest way to run a spider.

Here’s the code for a spider that scrapes blog posts from the Erlang
Solutions blog:  https://www.erlang-solutions.com/blog.html,
following the pagination:

```elixir
defmodule Esl do
@behaviour Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.erlang-solutions.com"

  def init() do
    [
      start_urls: ["https://www.erlang-solutions.com/blog.html"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # Getting new urls to follow
    urls =
      response.body
      |> Floki.find("a.more")
      |> Floki.attribute("href")
      |> Enum.uniq()

    # Convert URLs into requests
    requests =
      Enum.map(urls, fn url ->
        url
        |> build_absolute_url(response.request_url)
        |> Crawly.Utils.request_from_url()
      end)

    # Extract item from a page, e.g.
    # https://www.erlang-solutions.com/blog/introducing-telemetry.html
    title =
      response.body
      |> Floki.find("article.blog_post h1:first-child")
      |> Floki.text()

    author =
      response.body
      |> Floki.find("article.blog_post p.subheading")
      |> Floki.text(deep: false, sep: "")
      |> String.trim_leading()
      |> String.trim_trailing()

    time =
      response.body
      |> Floki.find("article.blog_post p.subheading time")
      |> Floki.text()

    url = response.request_url

    %Crawly.Parseditem{
      :requests => requests,
      :items => [%{title: title, author: author, time: time, url: url}]
    }
  end

  def build_absolute_url(url, request_url) do
    URI.merge(request_url, url) |> to_string()
  end
end
```

Put this code into your project and run it using the Crawly REST API:
`curl -v localhost:4001/spiders/Esl/schedule`

When it finishes you will get the ESL.jl file stored on your
filesystem containing the following information about blog posts:

```json
{"url":"https://www.erlang-solutions.com/blog/erlang-trace-files-in-wireshark.html","title":"Erlang trace files in Wireshark","time":"2018-06-07","author":"by Magnus Henoch"}
{"url":"https://www.erlang-solutions.com/blog/railway-oriented-development-with-erlang.html","title":"Railway oriented development with Erlang","time":"2018-06-13","author":"by Oleg Tarasenko"}
{"url":"https://www.erlang-solutions.com/blog/scaling-reliably-during-the-world-s-biggest-sports-events.html","title":"Scaling reliably during the World’s biggest sports events","time":"2018-06-21","author":"by Erlang Solutions"}
{"url":"https://www.erlang-solutions.com/blog/escalus-4-0-0-faster-and-more-extensive-xmpp-testing.html","title":"Escalus 4.0.0: faster and more extensive XMPP testing","time":"2018-05-22","author":"by Konrad Zemek"}
{"url":"https://www.erlang-solutions.com/blog/mongooseim-3-1-inbox-got-better-testing-got-easier.html","title":"MongooseIM 3.1 -
Inbox got better, testing got easier","time":"2018-07-25","author":"by
Piotr Nosek"}
....
```

## What just happened?

When you ran the curl command:
```curl -v localhost:4001/spiders/Esl/schedule```

Crawly runs a spider ESL, Crawly looked for a Spider definition inside
it and ran it through its crawler engine.

The crawl started by making requests to the URLs defined in the
start_urls attribute of the spider's init, and called the default
callback method `parse_item`, passing the response object as an
argument. In the parse callback, we loop:
1. Look through all pagination the elements using a Floki Selector and
extract absolute URLs to follow. URLS are converted into Requests,
using
`Crawly.Utils.request_from_url()` function
2. Extract item(s) (items are defined in separate modules, and this part
will be covered later on)
3. Return a Crawly.ParsedItem structure which is containing new
requests to follow and items extracted from the given page, all
following requests are going to be processed by the same `parse_item` function.

Crawly is fully asynchronous. Once the requests are scheduled, they
are picked up by separate workers and are executed in parralel. This
also means that other requests can keep going even if some request
fails or an error happens while handling it.


While this enables you to do very fast crawls (sending multiple
concurrent requests at the same time, in a fault-tolerant way) Crawly
also gives you control over the politeness of the crawl through a few
settings. You can do things like setting a download delay between each
request, limiting amount of concurrent requests per domain or
respecting robots.txt rules

```
This is using JSON export to generate the JSON lines file, but you can
easily extend it to change the export format (XML or CSV, for
example).

```

## What else?

You’ve seen how to extract and store items from a website using
Crawly, but this is just the basic example. Crawly provides a lot of
powerful features for making scraping easy and efficient, such as:

1. Flexible requets spoofing (for example user-agents rotation,
cookies management(this feature is planned))
2. Items validation, using pipelines approach
3. Filtering already seen requests and items
4. Filter out all requests which are comming to other domains
5. Robots.txt enforcement
6. Concurrency control
7. HTTP API for controlling crawlers
8. Interactive console, which allows to create and debug spiders

# Ethical aspects of crawling
---

It's important to be polite, when doing a web crawling. You should
avoid cases when your spiders are putting harm on the scrapped
websites. As it's mentioned here: https://blog.scrapinghub.com/2016/08/25/how-to-crawl-the-web-politely-with-scrapy#comments-listing

1. A polite crawler respects robots.txt
2. A polite crawler never degrades a website’s performance
3. A polite crawler identifies its creator with contact information
4. A polite crawler is not a pain in the buttocks of system
administrators

# Installation guide
---

Crawly requires Elixir v1.4 and higher. In order to make a Crawly
project execute the following steps:

1. Generate an new Elixir project: `mix new <project_name> --sup`
2. Add Crawly to you mix.exs file
    ```elixir
    def deps do
        [{:crawly, "~> 0.1"}]
    end
    ```
3. Fetch crawly: `mix deps.get`

# Crawly tutorial
---

In this tutorial, we’ll assume that Elixir is already installed on
your system. If that’s not the case, see Installation guide:
https://elixir-lang.org/install.html

We are going to scrape `https://www.homebase.co.uk`, a website that
contains products of different types.

This tutorial will walk you through these tasks:
1. Creating a new Crawly project
2. Writing a spider to crawl a site and extract data
3. Exporting the scraped data

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

```mix new tutorial --sup```

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
        [{:crawly, "~> 0.1"}]
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
downloaded by Crawly. It must return the `Crawly.ParsedItem` sturcture.


## How to run our spider

To put our spider to work, go to the project’s top level directory and
run:

1. iex -S mix - It will start the Elixir application which we have
created, and will open interactive console
2. Execute the following command in the opened Elixir console:
```Crawly.Engine.start_spider(Homebase)```

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
(processes responsible for downloading requests) did not have a work
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
contain herf attribute of links selected with
`a.category-block-heading__title` css selector. These URLs can will be
used in order to feed Crawly with requests to follow.

In order to find the proper CSS selectors to use, you might find
useful opening the target page from the shell in your web browse. You
can use your browser developer tools to inspect the HTML and come up
with a selector.

Now lets navigate to one of the homebase's product pages and extract
data from it.

```
{:ok, response} =
Crawly.fetch("https://www.homebase.co.uk/4-tier-heavy-duty-shelving-unit_p375180")

```

Extract `title` with:
```
response.body |> Floki.find(".page-title h1") |> Floki.text()
"4 Tier Heavy Duty Shelving Unit"
```

Extract `SKU` with:

```
response.body |> Floki.find(".product-header-heading span") |> Floki.text
"SKU:  375180"
```

Extract `price` with:
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
    # Extract product categories URLs
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
17:23:42.536 [debug] Scraped %{price: "£3.99", sku: "SKU:  486386",
title: "Bon Safety EN20471 Hi viz Yellow Vest, size XL"}
17:23:43.432 [debug] Scraped %{price: "£3.99", sku: "SKU:  486384",
title: "Bon Safety EN20471 Hi viz Yellow Vest, size L"}
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

# Basic concepts
---

## Spiders

Spiders are modules which define how a certain site (or a group of
sites) will be scraped, including how to perform the crawl
(i.e. follow links) and how to extract structured data from their
pages (i.e. scraping items). In other words, Spiders are the place
where you define the custom behaviour for crawling and parsing pages
for a particular site.

For spiders, the scraping cycle goes through something like this:

You start by generating the initial Requests to crawl the first URLs,
and use a callback function used e called with the response downloaded
from those requests.

In the callback function, you parse the response (web page) and return
a ` %Crawly.ParsedItem{}` struct. This struct should contain new
requests to follow and items to be stored.

In callback functions, you parse the page contents, typically using
Floki (but you can also use any other library you prefer) and generate
items with the parsed data.

Spiders are executed in the context of Crawly.Worker processes, and
you can control the amount of concurrent workers via
`concurrent_requests_per_domain` setting.

All requests are being processed sequentially and are pre-processed by
Middlewares.

All items are processed sequentially and are processed by Item pipelines.

### Behaviour functions

In order to make a working web crawler, all behaviour callbacks needs
to be implemented.

`init()` - a part of the Crawly.Spider behaviour. This function should
return a KVList which contains `start_urls` list, which defines the
starting requests made by Crawly.

`base_url()` - defines a base_url of the given Spider. This function
is used in order to filter out all requests which are going outside of
the crawled website.

`parse_item(response)` - a function which defines how a given response
is translated into the `Crawly.ParsedItem` structure. On the high
level this function defines the extraction rules for both Items and Requests.

## Requests and Responses

Crawly uses Request and Response objects for crawling web sites.

Typically, Request objects are generated in the spiders and pass
across the system until they reach the Crawly.Worker process, which
executes the request and returns a Response object which travels back
to the spider that issued the request. The requests objects are being
modified by the selected Middlewares, before hitting the worker.

The request is defined as the following structure:
``` elixir
  @type t :: %Crawly.Request{
    url: binary(),
    headers: [header()],
    prev_response: %{},
    options: [option()]
    }

@type header() :: {key(), value()}
  ```

Where:
1. url - is the url of the request
2. headers - define http headers which are going to be used with the
   given request
3. options - would define options (like follow redirects).

Crawly uses HTTPoison library to perform the requests, but we have
plans to extend the support with other pluggable backends like
selenium and others.

Responses are defined in the same way as HTTPoison responses. See more
details here: https://hexdocs.pm/httpoison/HTTPoison.Response.html#content

## Parsed Item

ParsedItem is a structure which is filled by the `parse_item/1`
callback of the Spider. The structure is defined in the following way:

```elixir
  @type item() :: %{}
  @type t :: %__MODULE__{
    items: [item()],
    requests: [Crawly.Request.t()]
    }

```
The parsed item is being processed by Crawly.Worker process, which
sends all requests to the `Crawly.RequestsStorage` process,
responsible for pre-processing requests and storing them for the
future execution, all items are being sent to `Crawly.DataStorage`
process, which is responsible for pre-processing item and storing it
on disk.

For now only one Storage backend is supported (writing on disc). But
in future Crawly will also support work with amazon S3, sql and others.

## Request Middlewares

Crawly is using a concept of pipelines when it comes to processing of
the elements sent to the system. In this section we will cover the
topic of requests middlewares - a powerful tool which allows to modify
the request before sending it to the target website. In most of the
spider developers would want to modify request headers, which allows
requests to look more natural to the crawled websites.

At this point Crawly includes the following request middlewares:
1. `Crawly.Middlewares.DomainFilter` - this middleware will disable
   scheduling for all requests leading outside of the crawled
   site. The middleware uses `base_url()` defined in the
   `Crawly.Spider` behaviour in order to do it's job
2. ` Crawly.Middlewares.RobotsTxt` - this middleware ensures that
Crawly respects the robots.txt defined by the target website.
3. `Crawly.Middlewares.UniqueRequest` - this middleware ensures that
crawly would not schedule the same URL(request) multiple time.
4. `Crawly.Middlewares.UserAgent` - this middleware is used to set a
   User Agent http header. Allows to rotate UserAgents, if the last
   one is defined as a list.

A list of request middlewares which are going to be used with a given
project are defined in the project settings.

## Item pipelines

Crawly is using a concept of pipelines when it comes to processing of
the elements sent to the system. In this section we will cover the
topic of item pipelines - a tool which is used in order to pre-process
items before storing them in the storage.

At this point Crawly includes the following Item pipelines:
1.  `Crawly.Pipelines.Validate` - validates that a given item has all
the required fields. All items which don't have all required fields
are dropped.
2.  `Crawly.Pipelines.DuplicatesFilter` - filters out items which are
already stored the system.
3. `Crawly.Pipelines.JSONEncoder`- converts items into JSON format (so
they are stored in JSON)

The list of item pipelines used with a given project is defined in the
project settings.

## Settings

The Crawly settings allows you to customize the behaviour of all
Crawly components, including crawling speed, used pipelines and middlewares.

Here’s a list of all available Crawly settings, along with their
default values and the scope where they apply.

The scope, where available, shows where the setting is being used, if
it’s tied to any particular component. In that case the module of that
component will be shown, typically an extension, middleware or
pipeline. It also means that the component must be enabled in order
for the setting to have any effect.

The settings are defined in the Elixir config style. For example:

```elixir
config :crawly,
  # The path where items are stored
  base_store_path: "/tmp/",
  # Item definition
  item: [:title, :author, :time, :url],
  # Identifier which is used to filter out duplicates
  item_id: :title,
```

### base_store_path :: binary()

default: "/tmp"

Defines the path where items are stored on the filesystem. This setting
is used by Crawly.DataStorageWorker process.

### user_agents :: list()

default: ["Crawly Bot 1.0"]

Defines a user agent string for Crawly requests. This setting is used
by `Crawly.Middlewares.UserAgent` middleware. In case if the list has
more than one item, all requests will be executed with a randomly
picked (from the supplied list) user agent string.

### item :: [atom()]

default: []

Defines a list of required fields for the item. In case if all default
fields are not added to the following item (or if the values of
required fields are "" or nil) the item will be dropped. This setting
is used by ` Crawly.Pipelines.Validate` pipeline

### item_id :: atom()

default: nil

Defines a field which will be used in order to identify if product is
duplicate or not. In most of the ecommerce websites the desired id
field is SKU. This setting is used in
`Crawly.Pipelines.DuplicatesFilter` pipeline. If unset the related
middleware is effectively disabled.

### pipelines :: [module()]

default: []

Defines a list of pipelines responsible for pre processing all scraped
items. All items not passing any of the pipelines are dropped. If
unset all items are stored without any modifications.

Example configuration of item pipelines:
```
config :crawly,
  pipelines: [
    Crawly.Pipelines.Validate,
    Crawly.Pipelines.DuplicatesFilter,
    Crawly.Pipelines.JSONEncoder
    ]
    ```

#### CSVEncoder pipeline

It's possible to export data in CSV format, if the pipelines are
defined in the following way:
```
config :crawly,
  pipelines: [
    Crawly.Pipelines.Validate,
    Crawly.Pipelines.DuplicatesFilter,
    Crawly.Pipelines.CSVEncoder
    ],
    output_format: "csv"
    ```

** NOTE: It's required to set output format to csv for the CSVEncoder pipeline


### middlewares :: [module()]

default:  [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    Crawly.Middlewares.RobotsTxt,
    Crawly.Middlewares.UserAgent
    ]

Defines a list of middlewares responsible for pre-processing
requests. If any of the requests from the `Crawly.Spider` is not
passing the middleware, it's dropped.

### closespider_itemcount :: pos_integer()

default: 5000

An integer which specifies a number of items. If the spider scrapes
more than that amount and those items are passed by the item pipeline,
the spider will be closed. If set to nil the spider will not be
stopped.

### closespider_timeout :: pos_integer()

default: nil

Defines a minimal amount of items which needs to be scraped by the
spider within the given timeframe (30s). If the limit is not reached
by the spider - it's being closed.

### follow_redirects :: boolean()

default: false

Defines is Crawly spider is supposed to follow HTTP redirects.

### concurrent_requests_per_domain :: pos_integer()

default: 4

The maximum number of concurrent (ie. simultaneous) requests that will
be performed by the Crawly workers.

### using crawly with proxy

Now it's possible to direct all Crawly's requests through a proxy,
it's possible to set proxy using the proxy value of Crawly config, for example:
```
config :crawly,
    proxy: "<proxy_host>:<proxy_port>",
    ```

Example usage:
```
iex(3)> Crawly.fetch("http://httpbin.org/ip")
{:ok,
 %HTTPoison.Response{
   body: "{\n  \"origin\": \"101.4.136.34, 101.4.136.34\"\n}\n",
   headers: [
     {"Server", "nginx/1.7.10"},
     {"Date", "Sat, 03 Aug 2019 18:57:20 GMT"},
     {"Content-Type", "application/json"},
     {"Content-Length", "45"},
     {"Connection", "keep-alive"},
     {"Access-Control-Allow-Credentials", "true"},
     {"Access-Control-Allow-Origin", "*"},
     {"Referrer-Policy", "no-referrer-when-downgrade"},
     {"X-Content-Type-Options", "nosniff"},
     {"X-Frame-Options", "DENY"},
     {"X-XSS-Protection", "1; mode=block"}
   ],
   request: %HTTPoison.Request{
     body: "",
     headers: [],
     method: :get,
     options: [false, {:proxy, "101.4.136.34:81"}],
     params: %{},
     url: "http://httpbin.org/ip"
   },
   request_url: "http://httpbin.org/ip",
   status_code: 200
 }}
```


# HTTP API
---

Crawly supports a basic HTTP API, which allows to control the Engine
behaviour.

## Starting a spider

The following command will start a given Crawly spider:

```
curl -v localhost:4001/spiders/<spider_name>/schedule
```

## Stopping a spider

The following command will stop a given Crawly spider:

```
curl -v localhost:4001/spiders/<spider_name>/stop
```

## Getting currently running spiders

```
curl -v localhost:4001/spiders
```

## Getting spider stats

```
curl -v localhost:4001/spiders/<spider_name>/scheduled-requests
curl -v localhost:4001/spiders/<spider_name>/scraped-items
```


# Extending Crawly
---
This section is not ready yet. To add.
