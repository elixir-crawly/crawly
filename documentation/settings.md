# Crawly settings

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
  item_id: :title
```

### base_store_path :: binary() [DEPRECATED in 0.6.0]

default: "/tmp"

Defines the path where items are stored in the filesystem. This setting
is used by the Crawly.DataStorageWorker process.

### user_agents :: list()

default: ["Crawly Bot 1.0"]

Defines a user agent string for Crawly requests. This setting is used
by the `Crawly.Middlewares.UserAgent` middleware. When the list has more than one
item, all requests will be executed, each with a user agent string chosen
randomly from the supplied list.

### item :: [atom()]

default: []

Defines a list of required fields for the item. When none of the default
fields are added to the following item (or if the values of
required fields are "" or nil), the item will be dropped. This setting
is used by the `Crawly.Pipelines.Validate` pipeline

### item_id :: atom()

default: nil

Defines a field which will be used in order to identify if an item is
a duplicate or not. In most of the ecommerce websites the desired id
field is the SKU. This setting is used in
the `Crawly.Pipelines.DuplicatesFilter` pipeline. If unset, the related
middleware is effectively disabled.

### pipelines :: [module()]

default: []

Defines a list of pipelines responsible for pre processing all the scraped
items. All items not passing any of the pipelines are dropped. If
unset, all items are stored without any modifications.

Example configuration of item pipelines:
```
config :crawly,
  pipelines: [
    Crawly.Pipelines.Validate,
    Crawly.Pipelines.DuplicatesFilter,
    Crawly.Pipelines.JSONEncoder,
    Crawly.Pipelines.WriteToFile [NEW IN 0.6.0]
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
    Crawly.Pipelines.CSVEncoder,
    Crawly.Pipelines.WriteToFile [NEW IN 0.6.0]
    ]
```

**NOTE**: Set the file extension config for `WriteToFile` to "csv"

#### JSONEncoder pipeline

It's possible to export data in CSV format, if the pipelines are
defined in the following way:
```
config :crawly,
  pipelines: [
    Crawly.Pipelines.Validate,
    Crawly.Pipelines.DuplicatesFilter,
    Crawly.Pipelines.JSONEncoder,
    Crawly.Pipelines.WriteToFile [NEW IN 0.6.0]
    ]
```

**NOTE**: Set the file extension config for `WriteToFile` to "jl"

#### WriteToFile pipeline

Writes a given item to a file.
```
config :crawly,
  pipelines: [
    ...
    Crawly.Pipelines.JSONEncoder,
    Crawly.Pipelines.WriteToFile
    ]

config :crawly, Crawly.Pipelines.WriteToFile,
  folder: "/tmp",
  extension: "jl"

```

**NOTE**: Set the file extension config for `WriteToFile` to "jl"

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
by the spider - it will be stopped.

### follow_redirects :: boolean()

default: false

Defines is Crawly spider is supposed to follow HTTP redirects or not.

### concurrent_requests_per_domain :: pos_integer()

default: 4

The maximum number of concurrent (ie. simultaneous) requests that will
be performed by the Crawly workers.

### using crawly with a proxy

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
