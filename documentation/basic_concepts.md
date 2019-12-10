# Basic Concepts

---

## Spiders

Spiders are modules which define how a certain site (or a group of sites) will be scraped, including how to perform the crawl (i.e. follow links) and how to extract structured data from their pages (i.e. scraping items). In other words, Spiders are the place where you define the custom behaviour for crawling and parsing pages for a particular site.

For spiders, the scraping cycle goes through something like this:

You start by generating the initial Requests to crawl the first URLs, and use a callback function called with the response downloaded from those requests.

In the callback function, you parse the response (web page) and return a `%Crawly.ParsedItem{}` struct. This struct should contain new requests to follow and items to be stored.

In the callback functions, you parse the page contents, typically using Floki (but you can also use any other library you prefer) and generate items with the parsed data.

Spiders are executed in the context of Crawly.Worker processes, and you can control the amount of concurrent workers via `concurrent_requests_per_domain` setting.

All requests are being processed sequentially and are pre-processed by Middlewares.

All items are processed sequentially and are processed by Item pipelines.

### Behaviour functions

In order to make a working web crawler, all the behaviour callbacks need to be implemented.

`init()` - a part of the Crawly.Spider behaviour. This function should return a KVList which contains a `start_urls` entry with a list, which defines the starting requests made by Crawly.

`base_url()` - defines a base_url of the given Spider. This function is used in order to filter out all requests which are going outside of the crawled website.

`parse_item(response)` - a function which defines how a given response is translated into the `Crawly.ParsedItem` structure. On the high level this function defines the extraction rules for both Items and Requests.

## Requests and Responses

Crawly uses Request and Response objects for crawling web sites.

Typically, Request objects are generated in the spiders and pass across the system until they reach the Crawly.Worker process, which executes the request and returns a Response object which travels back to the spider that issued the request. The Request objects are being modified by the selected Middlewares, before hitting the worker.

The request is defined as the following structure:

```elixir
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
2. headers - define http headers which are going to be used with the given request
3. options - would define options (like follow redirects).

Crawly uses HTTPoison library to perform the requests, but we have plans to extend the support with other pluggable backends like selenium and others.

Responses are defined in the same way as HTTPoison responses. See more details here: https://hexdocs.pm/httpoison/HTTPoison.Response.html#content

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

The parsed item is being processed by Crawly.Worker process, which sends all requests to the `Crawly.RequestsStorage` process, responsible for pre-processing requests and storing them for the future execution, all items are being sent to `Crawly.DataStorage` process, which is responsible for pre-processing items and storing them on disk.

For now only one Storage backend is supported (writing on disc). But in future Crawly will also support work with amazon S3, sql and others.

## Request Middlewares

These are configured under the `middlewares` option. See [configuration](./configuration.md) for more details.

> **Middleware:** A pipeline module that modifies a request. It implements the `Crawly.Pipeline` behaviour.

List of built-in middlewares:

1. `Crawly.Middlewares.DomainFilter` - this middleware will disable scheduling for all requests leading outside of the crawled site.
2. `Crawly.Middlewares.RobotsTxt` - this middleware ensures that Crawly respects the robots.txt defined by the target website.
3. `Crawly.Middlewares.UniqueRequest` - this middleware ensures that crawly would not schedule the same URL(request) multiple times.
4. `Crawly.Middlewares.UserAgent` - this middleware is used to set a User Agent HTTP header. Allows to rotate UserAgents, if the last one is defined as a list.

## Item Pipelines

Crawly is using a concept of pipelines when it comes to processing of the elements sent to the system. In this section we will cover the topic of item pipelines - a tool which is used in order to pre-process items before storing them in the storage.

At this point Crawly includes the following Item pipelines:

1.  `Crawly.Pipelines.Validate` - validates that a given item has all the required fields. All items which don't have all required fields are dropped.
2.  `Crawly.Pipelines.DuplicatesFilter` - filters out items which are already stored the system.
3.  `Crawly.Pipelines.JSONEncoder`- converts items into JSON format.
4.  `Crawly.Pipelines.CSVEncoder`- converts items into CSV format.
5.  `Crawly.Pipelines.WriteToFile`- Writes information to a given file.

The list of item pipelines used with a given project is defined in the project settings.
