import Config

config :crawly,
  start_http_api?: true,
  manager_operations_timeout: 500,
  # Stop spider after scraping certain amount of items
  closespider_itemcount: 100,
  # Stop spider if it does crawl fast enough
  closespider_timeout: 20,
  concurrent_requests_per_domain: 5,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    Crawly.Middlewares.RobotsTxt,
    {Crawly.Middlewares.UserAgent, user_agents: ["My Custom Bot"]}
  ],
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:title, :url, :time, :author]},
    {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
    Crawly.Pipelines.JSONEncoder
  ],
  retry: [
    retry_codes: [500, 404],
    max_retries: 2,
    ignored_middlewares: [Crawly.Middlewares.UniqueRequest]
  ],
  log_dir: "/tmp/spider_logs"
