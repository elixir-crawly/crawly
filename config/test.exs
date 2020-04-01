use Mix.Config

config :crawly,
       manager_operations_timeout: 30_000,

         # Stop spider after scraping certain amount of items
       closespider_itemcount: 100,
         # Stop spider if it does crawl fast enough
       closespider_timeout: 20,
       concurrent_requests_per_domain: 5,
       follow_redirect: true,

       # Request middlewares
       # User agents which are going to be used with requests
       user_agents: [
         "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0",
         "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36",
         "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41"
       ],
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
       ]

