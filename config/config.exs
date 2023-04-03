# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :logger,
  backends: [:console, {LoggerFileBackend, :info_log}]

config :crawly,
  log_dir: "/tmp/spider_logs",
  log_to_file: true,
  fetcher: {Crawly.Fetchers.HTTPoisonFetcher, []},
  retry: [
    retry_codes: [400],
    max_retries: 3,
    ignored_middlewares: [Crawly.Middlewares.UniqueRequest]
  ],

  # Stop spider after scraping certain amount of items
  closespider_itemcount: 500,
  # Stop spider if it does crawl fast enough
  closespider_timeout: 20,
  concurrent_requests_per_domain: 5,

  # Request middlewares
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    Crawly.Middlewares.RobotsTxt,
    {Crawly.Middlewares.UserAgent,
     user_agents: [
       "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0",
       "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36",
       "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41"
     ]}
  ],
  pipelines: [
    {Crawly.Pipelines.Validate, fields: ["title", "body", "url"]},
    {Crawly.Pipelines.DuplicatesFilter, item_id: "title"},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "jl"}
  ]

import_config "#{Mix.env()}.exs"
