import Config

# Same as examples/quickstart, except:
#   * no item limit, so the whole local copy (180 books) is crawled
#   * items are written to tmp/ inside this project
#   * the manager checks the spider every 15 s instead of every 60 s, so the
#     crawl stops soon after the last page (it stops on the first check that
#     finds no queued requests and no new items)
#   * closespider_timeout is off: with 15 s checks it would stop a healthy
#     crawl during the 10 s pause each worker takes between requests
config :crawly,
  manager_operations_timeout: 15_000,
  closespider_timeout: :disabled,
  concurrent_requests_per_domain: 8,
  closespider_itemcount: :disabled,
  middlewares: [
    Crawly.Middlewares.SameDomainFilter,
    Crawly.Middlewares.UniqueRequest,
    {Crawly.Middlewares.UserAgent, user_agents: ["Crawly Bot"]}
  ],
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:url, :title, :price]},
    {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "tmp"}
  ]
