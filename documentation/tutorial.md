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
        {:crawly, "~> 0.13.0"},
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
books_to_scrape.ex under the lib/tutorial/spiders directory of your project.

```elixir
defmodule BooksToScrape do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://books.toscrape.com/"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://books.toscrape.com/"
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

As it is, the init function returns an empty list for `start_urls` which we will
fix now. If you already know what urls you want to start crawling, you can place them in
the list, else you can pick the urls you want to start with from a particular page
on your website of interest.


> Note: You can use the iex shell to test your selectors on the response HTML using Floki. Alternatively, use your browser's developer tools to test your selector.

## How to run our spider

To put our spider to work, go to the project’s top level directory and
run:

1. `iex -S mix` - It will start the Elixir application which we have
   created, and will open interactive console.
2. Execute the following command in the opened Elixir console:
   `Crawly.Engine.start_spider(BooksToScrape)`

You will get an output similar to this:

```
iex(2)> Crawly.Engine.start_spider(BooksToScrape)

14:07:50.188 [debug] Starting the manager for Elixir.BooksToScrape

14:07:50.188 [debug] Starting requests storage worker for Elixir.BooksToScrape...

14:07:50.987 [debug] Started 4 workers for Elixir.BooksToScrape
:ok

14:08:50.990 [info]  Current crawl speed is: 0 items/min
14:08:50.990 [info]  Stopping BooksToScrape, itemcount timeout achieved
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
   `response = Crawly.fetch("https://books.toscrape.com/")`

You will see something like:

```elixir
%HTTPoison.Response{
  body: "[response body here]",
  headers: [
    {"Server", "nginx/1.17.7"},
    {"Date", "Mon, 16 Aug 2021 19:58:15 GMT"},
    {"Content-Type", "text/html"},
    {"Content-Length", "50607"},
    {"Connection", "keep-alive"},
    {"Vary", "Accept-Encoding"},
    {"Last-Modified", "Thu, 25 Mar 2021 13:59:05 GMT"},
    {"Accept-Ranges", "bytes"},
    {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"}
  ],
  request: %HTTPoison.Request{
    body: "",
    headers: [],
    method: :get,
    options: [],
    params: %{},
    url: "https://books.toscrape.com/"
  },
  request_url: "https://books.toscrape.com/",
  status_code: 200
}
```

Now let's start parsing the document and extract the books in it.

```elixir
response = Crawly.fetch("https://books.toscrape.com/")

```

All books on the page are enclosed in a `.product_pod` class. We can the select the class and pick the information we want from it.

```
items =
  document
  |> Floki.find(".product_pod")
  |> Enum.map(fn x ->
    %{
      title: Floki.find(x, "h3 a") |> Floki.attribute("title") |> Floki.text(),
      price: Floki.find(x, ".product_price .price_color") |> Floki.text()
    }
  end)
```

Here we select all products using the class `.product_pod`, then we iterate over each html fragment found and extract out relevant product information. In this case, we want to extract the title and price. `Floki.find(x, "h3 a") |> Floki.attribute("title") |> Floki.text()` for the title and for the price `Floki.find(x, ".product_price .price_color") |> Floki.text()`. The full text of the book name is only contained in the title attribute and not in the text node of the `a` tag, hence our use of the title attribute.

To handle pagination, we'll tell Crawly to visit the next page by extracting the next pages' urls and building new requests from them.

> Pagination url extraction can be within the same callback, as if there are no pagination HTML nodes found, next_requests would be an empty list.

```elixir
next_requests =
  document
  |> Floki.find(".next a")
  |> Floki.attribute("href")
  |> Enum.map(fn url ->
    Crawly.Utils.build_absolute_url(url, response.request.url)
    |> Crawly.Utils.request_from_url()
  end)
```

Here we get the url for the next page using Floki, which could be an empty list if such doesn't exist, this would mean that we have gotten to the last page and will result in the spider stopping. 
We then create a `Crawly.Request` struct by piping the url we got from Floki to `Crawly.Utils.build_absolute_url/2` and `Crawly.Utils.request_from_url/1`.

## Extracting data in our spider

Let’s get back to our spider. Until now, it doesn’t extract any data,
just makes an `empty run`. Let’s integrate the extraction logic above
into our spider.

```elixir
defmodule BooksToScrape do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://books.toscrape.com/"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://books.toscrape.com/"
      ]
    ]
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

You will also need to tell Crawly where to store the scraped data. Create `config/config.exs` file with the following
contents:
```elixir
use Mix.Config

config :crawly,
  pipelines: [
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "jl"}
  ]
```
The scraped data will now be stored in a CSV file under `/tmp` directory on your filesystem. The name of the file
will be the same as our spider name - in our case `BooksToScrape.jl`.

If you restart iex and run this spider `Crawly.Engine.start_spider(BooksToScrape)`, it will output messages like:

```
08:43:09.677 [debug] Dropping request: https://books.toscrape.com/catalogue/category/books/new-adult_20/index.html, as it's already processed
```

That's because Crawly filters out requests which it has already visited during the current run.

Go ahead and check the contents of your `/tmp/Homebase.jl` file. It should contain the scraped products like these:
```
{"title":"A Light in the Attic","price":"£51.77"}
{"title":"Tipping the Velvet","price":"£53.74"}
{"title":"Soumission","price":"£50.10"}
{"title":"Sharp Objects","price":"£47.82"}
```

## Next steps

This tutorial covered only the basics of Crawly, but there’s a lot of
other features not mentioned here.

You can continue from the section Basic concepts to know more about
the basic Crawly features.
