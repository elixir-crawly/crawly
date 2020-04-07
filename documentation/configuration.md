# Configuration

---

A basic example:

```elixir
config :crawly,
  pipelines: [
    # my pipelines
  ],
  middlewares: [
    # my middlewares
  ]
```

## Options

### `pipelines` :: [module()]

default: []

Defines a list of pipelines responsible for pre processing all the scraped items. All items not passing any of the pipelines are dropped. If unset, all items are stored without any modifications.

Example configuration of item pipelines:

```
config :crawly,
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:id, :date]},
    {Crawly.Pipelines.DuplicatesFilter, item_id: :id},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"} # NEW IN 0.6.0
    ]
```

### middlewares :: [module()]

Example middlewares
```elixir
config :crawly,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    Crawly.Middlewares.RobotsTxt,
    {Crawly.Middlewares.UserAgent, user_agents: ["My Bot"] },
    {Crawly.Middlewares.RequestOptions, [timeout: 30_000, recv_timeout: 15000]}
  ]
```

Defines a list of middlewares responsible for pre-processing requests. If any of the requests from the `Crawly.Spider` is not passing the middleware, it's dropped.

### closespider_itemcount :: pos_integer() | :disabled

default: :disabled

An integer which specifies a number of items. If the spider scrapes more than that amount and those items are passed by the item pipeline, the spider will be closed. If set to :disabled the spider will not be stopped.

### closespider_timeout :: pos_integer() | :disabled

default: nil

Defines a minimal amount of items which needs to be scraped by the spider within the given timeframe (30s). If the limit is not reached by the spider - it will be stopped.


### concurrent_requests_per_domain :: pos_integer()

default: 4

The maximum number of concurrent (ie. simultaneous) requests that will be performed by the Crawly workers.

### retry :: Keyword list

Allows to configure the retry logic. Accepts the following configuration options:
1) *retry_codes*: Allows to specify a list of HTTP codes which are treated as
   failed responses. (Default: [])

2) *max_retries*: Allows to specify the number of attempts before the request is
   abandoned. (Default: 0)

3) *ignored_middlewares*: Allows to modify the list of processors for a given 
   requests when retry happens. (Will be required to avoid clashes with 
   Unique.Request middleware).
   
Example:
   ```
        retry:
            [
              retry_codes: [400],
              max_retries: 3,
              ignored_middlewares: [Crawly.Middlewares.UniqueRequest]
          ]

   ```

### fetcher :: atom()

default: Crawly.Fetchers.HTTPoisonFetcher

Allows to specify a custom HTTP client which will be performing request to the crawler target.

### port :: pos_integer()

default: 4001

Allows to specify a custom port to start the application. That is important when running more than one application in a single machine, in which case shall not use the same port as the others.

### on_spider_closed_callback :: function()

default: :ignored

Allows to define a callback function which will be executed when spider finishes
it's work.

## Overriding global settings on spider level

It's possible to override most of the setting on a spider level. In order to do that,
it is required to define the `override_settings/0` callback in your spider.

For example:
```elixir
def override_settings() do
   [
    concurrent_requests_per_domain: 5,
    closespider_timeout: 6
   ]
end
```

The full list of overridable settings:
  - closespider_itemcount,
  - closespider_timeout,
  - concurrent_requests_per_domain,
  - fetcher,
  - retry,
  - middlewares,
  - pipelines