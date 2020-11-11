# Basic Concepts

---
## Flow from Request, Response, Parsed Item
Data is fetched in a linear series of operations.

1. New `Request`s is formed through `Crawly.Spider.init/0`.
2. New `Request`s are pre-processed individually.
3. Data is fetched, and a `Response` is returned
4. The `Spider` receives the response and parses the response, returning new `Request`s and new parsed items
5. Parsed items are post-processed individually. New `Request`s from the `Spider` goes to step 2


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

`init()` - a part of the Crawly.Spider behaviour. This function should return a KVList which contains a `start_urls` entry with a list, which defines the starting requests made by Crawly. Alternatively you may provide `start_requests` if it's required
 to prepare first requests on `init()`. Which might be useful if, for example, you
 want to pass a session cookie to the starting request. Note: `start_requests` are
 processed before start_urls.
 ** This callback is going to be deprecated in favour of init/1. For now the backwords 
 compatibility is kept with a help of macro which always generates `init/1`.

`init(options)` same as `init/0` but also takes options (which can be passed from the engine during 
the spider start). 

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

## The `Crawly.Pipeline` Behaviour.

Crawly is using a concept of pipelines when it comes to processing of the elements sent to the system. This is applied to both request and scraped item manipulation. Conceptually, requests go through a series of manipulations, before the response is fetched. The response then goes through another different series of manipulations.

Importantly, the way that requests and responses are manipulated are abstracted into the `Crawly.Pipeline` behaviour. This allows for a modular system for declaring changes. It is also to be noted that Each `Crawly.Pipeline` module, when declared, are applied sequentially through the `Crawly.Utils.pipe/3` function.

### Writing Tests for Custom Pipelines

Modules that implement the `Crawly.Pipeline` behaviour can make use of the `Crawly.Utils.pipe/3` function to test for expected behaviour. Refer to the function documentation for more information and examples.

## Request Middlewares

These are configured under the `middlewares` option. See [configuration](configuration.html) for more details.

> **Middleware:** A pipeline module that modifies a request. It implements the `Crawly.Pipeline` behaviour.

Middlewares are able to make changes to the underlying request, a `Crawly.Request` struct. The request, along with any options specified, is then passed to the fetcher (currently `HTTPoison`).
The available configuration options should correspond to the underlying options of the fetcher in use.

Note that all request configuration options for `HTTPoison`, such as proxy, ssl, etc can be configured through `Crawly.Request.options`.

Built-in middlewares:

1. `Crawly.Middlewares.DomainFilter` - this middleware will disable scheduling for all requests leading outside of the crawled site.
2. `Crawly.Middlewares.RobotsTxt` - this middleware ensures that Crawly respects the robots.txt defined by the target website.
3. `Crawly.Middlewares.UniqueRequest` - this middleware ensures that crawly would not schedule the same URL(request) multiple times.
4. `Crawly.Middlewares.UserAgent` - this middleware is used to set a User Agent HTTP header. Allows to rotate UserAgents, if the last one is defined as a list.
5. `Crawly.Middlewares.RequestOptions` - allows to set additional request options, for example timeout, of proxy string (at this moment the options should match options of the individual fetcher (e.g. HTTPoison))
6. `Crawly.Middlewares.AutoCookiesManager` - allows to turn on the automatic cookies management. Useful for cases when you need to login or enter form data used by a website.
   Example:
   ```elixir
    {Crawly.Middlewares.RequestOptions, [timeout: 30_000, recv_timeout: 15000]},
     Crawly.Middlewares.AutoCookiesManager
   ```

### Item Pipelines

> **Item Pipelines:** a pipeline module that modifies and pre-processes a scraped item.

Built-in item pipelines:

1.  `Crawly.Pipelines.Validate` - validates that a given item has all the required fields. All items which don't have all required fields are dropped.
2.  `Crawly.Pipelines.DuplicatesFilter` - filters out items which are already stored the system.
3.  `Crawly.Pipelines.JSONEncoder`- converts items into JSON format.
4.  `Crawly.Pipelines.CSVEncoder`- converts items into CSV format.
5.  `Crawly.Pipelines.WriteToFile`- Writes information to a given file.

The list of item pipelines used with a given project is defined in the project settings.

## Creating a Custom Pipeline Module

Both item pipelines and request middlewares follows the `Crawly.Pipeline` behaviour. As such, when creating your custom pipeline, it will need to implement the required callback `c:Crawly.Pipeline.run\3`.

The `c:Crawly.Pipeline.run\3` callback receives the processed item, `item` from the previous pipeline module as the first argument. The second argument, `state`, is a map containing information such as spider which the item originated from (under the `:spider_name` key), and may optionally store pipeline information. Finally, `opts` is a keyword list containing any tuple-based options.

### Passing Configuration Options To Your Pipeline

Tuple-based option declaration is supported, similar to how a `GenServer` is declared in a supervision tree. This allows for pipeline reusability for different use cases.

For example, you can pass options in this way through your pipeline declaration:

```elixir
pipelines: [
  {MyCustomPipeline, my_option: "value"}
]
```

In your pipeline, you will then receive the options passed through the `opts` argument.

```elixir
defmodule MyCustomPipeline do
  @impl Crawly.Pipeline
  def run(item, state, opts) do
    IO.inspect(opts)        # shows keyword list of  [ my_option: "value" ]
    # Do something
  end
end
```


### Best Practices

The use of global configs is discouraged, hence one pass options through a tuple-based pipeline declaration where possible.

When storing information in the `state` map, ensure that the state is namespaced with the pipeline name, so as to avoid key clashing. For example, to store state from `MyEctoPipeline`, store the state on the key `:my_ecto_pipeline_my_state`.

### Custom Request Middlewares
#### Request Middleware Example - Add a Proxy

Following the [documentation](https://hexdocs.pm/httpoison/HTTPoison.Request.html) for proxy options of a request in `HTTPoison`, we can do the following:

```elixir
defmodule MyApp.MyProxyMiddleware do
  @impl Crawly.Pipeline
  def run(request, state, opts \\ []) do
    # Set default proxy and proxy_auth to nil
    opts = Enum.into(opts, %{proxy: nil, proxy_auth: nil})

    case opts.proxy do
      nil ->
        # do nothing
        {request, state}
      value ->
        old_options = request.options
        new_options = [proxy: opts.proxy, proxy_auth: opts.proxy_auth]
        new_request =  Map.put(request, :options, old_optoins ++ new_options)
        {new_request, state}
    end
  end
end
```


### Custom Item Pipelines
Item pipelines receives the parsed item (from the Spider) and performs post-processing on the item.

#### Storing Parsed Items
You can use custom item pipelines to save the item to custom storages.

##### Example - Ecto Storage Pipeline
In this example, we insert the scraped item into a table with Ecto. This example does not directly call `MyRepo.insert`, but delegates it to an application context function.

```elixir
defmodule MyApp.MyEctoPipeline do
  @impl Crawly.Pipeline
  def run(item, state, _opts \\ []) do
    case MyApp.insert_with_ecto(item) do
      {:ok, _} ->
        # insert successful, carry on with pipeline
        {item, state}
      {:error, _} ->
        # insert not successful, drop from pipeline
        {false, state}
    end
  end
end
```

#### Multiple Different Types of Parsed Items
If you need to selectively post-process different types of scraped items, you can utilize pattern-matching at the item pipeline level.

There are two general methods of doing so:
1. Struct-based pattern matching
  ```elixir
  defmodule MyApp.MyCustomPipeline do
    @impl Crawly.Pipeline
    def run(%MyItem{} = item, state, _opts \\ []) do
      # do something
    end
    # do nothing if it does not match
    def run(item, state, _opts), do: {item, state}
  end
  ```
2. Key-based pattern matching
  ```elixir
  defmodule MyApp.MyCustomPipeline do
    @impl Crawly.Pipeline
    def run(%{my_item: my_item} = item, state, _opts \\ []) do
      # do something
    end
    # do nothing if it does not match
    def run(item, state, _opts), do: {item, state}
  end
  ```

Use struct-based pattern matching when:
1. you want to utilize existing Ecto schemas
2. you have pre-defined structs that you want to conform to

Use key-based pattern matching when:
1. you want to process two or more related and inter-dependent items together
2. you want to bulk process multiple items for efficiency reasons. For example, processing the weather data for 365 days in one pass.

##### Caveats
When using the nested-key pattern matching method, the spider's `Crawly.Spider.parse_item/1` callback will need to return items with a single key (or a map with multiple keys, if doing related processing).

When using struct-based pattern matching with existing Ecto structs, you will need to do an intermediate conversion of the struct into a map before performing the insertion into the Ecto Repo. This is due to the underlying Ecto schema metadata still being attached to the struct before insertion.

##### Example - Multi-Item Pipelines With Pattern Matching
In this example, your spider scrapes a "blog post" and a "weather data" from a website.
We will use the key-based pattern matching approach to selectively post-process a blog post parsed item.


```elixir
# in MyApp.CustomSpider.ex
def parse_item(response):
  # parse my item
  %{parsed_items: [
    %{blog_post: blog_post} ,
    %{weather: [ january_weather, february_weather ]}
  ]}
```
Then, in the custom pipeline, we will pattern match on the `:blog_post` key, to ensure that we only process blog posts with this pipeline (and not weather data).
We then update the `:blog_post` key of the received item.
```elixir
defmodule MyApp.BlogPostPipeline do
  @impl Crawly.Pipeline
  def run(%{blog_post: old_blog_post} = item, state, _opts \\ []) do
    # process the blog post
    updated_item = Map.put(item, :blog_post, %{my: "data"})
    {updated_item, state}
  end
  # do nothing if it does not match
  def run(item, state, _opts), do: {item, state}
end
```

## Browser rendering

Browser rendering is one of the most complex problems of the scraping. The Internet
moves towards more dynamic content, where not only parts of the pages are loaded
asynchronously, but entire applications might be rendered by the JavaScript and
AJAX.

In most of the cases it's still possible to extract the data from dynamically
rendered pages. (E.g. by sending additional POST requests from loaded pages),
however this approach seems to have visible drawbacks. From our point of view
it makes the spider code quite complicated and fragile.

Of course it's good when you can just get pages already rendered for you. And we're
solving this problem with a help of pluggable HTTP fetchers.

Crawly's codebase contains a special Splash fetcher, which allows to do the browser
rendering before the page content is being parsed by a spider. Also it's possible
to build own fetchers.

### Using splash fetcher for browser rendering

Splash is a lightweight opensourse browser implementation built with QT and python.
See: https://splash.readthedocs.io/en/stable/api.html

You can try using Splash with Crawly in the following way:

1. Start splash locally (e.g. using a docker image):
` docker run -it -p 8050:8050 scrapinghub/splash --max-timeout 300`
2. Configure Crawly to use Splash:
`fetcher: {Crawly.Fetchers.Splash, [base_url: "http://localhost:8050/render.html"]}`
3. Now all your pages will be automatically rendered by Splash.