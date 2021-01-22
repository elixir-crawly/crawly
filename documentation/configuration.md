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
    {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp", include_timestamp: true}
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

### closespider_timeout :: pos_integer()

default: nil (disabled by default)

Defines a minimal amount of items which needs to be scraped by the spider within the given timeframe (1m). If the limit is not reached by the spider - it will be stopped.


### concurrent_requests_per_domain :: pos_integer()

default: 4

Indicates the number of Crawly workers that will be used to make simultaneous requests on a per-spider basis.

Each Crawly worker is rate-limited to a maximum of 4 requests per minute. Hence, by default, the number of requests possible would be `4 x 4 = 16 req/min`.

In order to increase the number of requests made per minute, set this option to a higher value. The default value is intentionally set at 4 for ethical crawling reasons.

NOTE: A worker's speed if often limited by the speed of the actual HTTP client and network bandwidth, and may be less than 4 requests per minute.

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

### log_dir :: String.t()

default: /tmp

Set spider logs directory. All spiders have their own dedicated log file 
stored under the `log_dir` folder.

### port :: pos_integer()

default: 4001

Allows to specify a custom port to start the application. That is important when running more than one application in a single machine, in which case shall not use the same port as the others.

### on_spider_closed_callback :: function()
default: :ignored

A function that takes three arguments: spider_name, crawl_id and reason of spider stop.
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
