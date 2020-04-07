defmodule Crawly.Settings do
  @moduledoc """
  Define Crawly setting types
  """

  @type numeric_setting() :: pos_integer() | :disabled
  @type retry() :: [
          retry_codes: [pos_integer()],
          max_retries: pos_integer(),
          ignored_middlewares: [module()]
        ]

  @type middleware() ::
          Crawly.Middlewares.DomainFilter
          | Crawly.Middlewares.UniqueRequest
          | Crawly.Middlewares.RobotsTxt
          | Crawly.Middlewares.AutoCookiesManager
          | {Crawly.Middlewares.UserAgent, user_agents: [binary()]}

  @type pipeline() ::
          Crawly.Pipelines.JSONEncoder
          | {Crawly.Pipelines.DuplicatesFilter, item_id: atom()}
          | {Crawly.Pipelines.Validate, fields: [atom()]}
          | {Crawly.Pipelines.CSVEncoder, fields: [atom()]}
          | {Crawly.Pipelines.WriteToFile,
             folder: binary(), extension: binary()}

  @type t() :: [
          # Allows to stop spider after a given number of scraped items
          # :disabled by default.
          closespider_itemcount: numeric_setting(),

          # Allows to stop spider if it extracts less than a given amount of
          # items per minute.
          closespider_timeout: pos_integer(),

          # Allows to control how many workers are started for a given domain
          concurrent_requests_per_domain: pos_integer(),

          # Allows to define a fetcher to perform HTTP requests
          fetcher: Crawly.Fetchers.Fetcher.t(),

          # Defines retries
          retry: retry(),
          middlewares: [middleware()],
          pipelines: [pipeline()],
          on_spider_closed_callback: function()
        ]
end
