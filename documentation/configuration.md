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

### base_store_path :: binary() [DEPRECATED in 0.6.0]

default: "/tmp"

Defines the path where items are stored in the filesystem. This setting
is used by the Crawly.DataStorageWorker process.

> **Deprecated**: This has been deprecated in favour of having pipelines to handle data storage, as of `0.6.0`

### `user_agents` :: list()

default: ["Crawly Bot 1.0"]

Defines a user agent string for Crawly requests. This setting is used
by the `Crawly.Middlewares.UserAgent` middleware. When the list has more than one
item, all requests will be executed, each with a user agent string chosen
randomly from the supplied list.

> **Deprecated**: This has been deprecated in favour of tuple-based pipeline configuration instead of global configurations, as of `0.7.0`. Refer to `Crawly.Middlewares.UserAgent` module documentation for correct usage.

### `item` :: [atom()]

default: []

Defines a list of required fields for the item. When none of the default
fields are added to the following item (or if the values of
required fields are "" or nil), the item will be dropped. This setting
is used by the `Crawly.Pipelines.Validate` pipeline

> **Deprecated**: This has been deprecated in favour of tuple-based pipeline configuration instead of global configurations, as of `0.7.0`. Refer to `Crawly.Pipelines.Validate` module documentation for correct usage.

### `item_id` :: atom()

default: nil

Defines a field which will be used in order to identify if an item is
a duplicate or not. In most of the ecommerce websites the desired id
field is the SKU. This setting is used in
the `Crawly.Pipelines.DuplicatesFilter` pipeline. If unset, the related
middleware is effectively disabled.

> **Deprecated**: This has been deprecated in favour of tuple-based pipeline configuration instead of global configurations, as of `0.7.0`. Refer to `Crawly.Pipelines.DuplicatesFilter` module documentation for correct usage.

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

### closespider_itemcount :: pos_integer()

default: 5000

An integer which specifies a number of items. If the spider scrapes more than that amount and those items are passed by the item pipeline, the spider will be closed. If set to nil the spider will not be stopped.

### closespider_timeout :: pos_integer()

default: nil

Defines a minimal amount of items which needs to be scraped by the spider within the given timeframe (30s). If the limit is not reached by the spider - it will be stopped.

### follow_redirect :: boolean()

default: false

Defines is Crawly spider is supposed to follow HTTP redirects or not.

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
