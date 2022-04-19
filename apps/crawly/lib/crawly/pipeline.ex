defmodule Crawly.Pipeline do
  @moduledoc """
  A behavior module for implementing a pipeline module. Pipelines allow for customization of how `Crawly.Requests`, `Crawly.Responses`, and `:items` set on `Crawly.ParsedItem` are processed. Each pipeline is called in sequence, with the result of each being passed to the next pipeline.

  A pipeline is a module which takes a given item, and executes a run callback on a given item.

  A state argument is used to share common information across multiple items. May have preset keys that are set internally by Crawly. Custom pipeline modules may set information to be further used down the declared list of pipeline modules.

  An `opts` argument is used to pass configuration to the pipeline through tuple-based declarations.


  ### Example Config Declaration
  ```elixir
  # config.exs
  :crawly,
    parsers: [
      # with options
      {Crawly.ExtractRequests, selector: "a" }
    ],
    middlewares: [
      Crawly.Middlewares.DomainFilter,
      Crawly.Middlewares.UniqueRequest,
      Crawly.Middlewares.RobotsTxt
    ],
    pipelines: [Crawly.Pipelines.JSONEncoder ]
  ```
  ### Request Middlewares
  Request middlewares are called for each request returned on the `:requests` key of a `ParsedItem`.

  ### Response Parsers
  The following are set on the state for parsers:
  - `:response`: A `Crawly.Response` struct. The response from the used `Fetcher`.
  - `:spider_name`: The name of the spider that is is currently being used. Can be used for processing customizations, logging, or referencing settings.

  Must return a `Map` on the first tuple position, which follows the same typespecs as a `ParsedItem`. Only recognized keys will be used.

  ### Item Pipelines
  Item pipelines are called for each enumerable result on the`:items` key of a `ParsedItem`.
  """
  @callback run(item :: map, state :: map()) ::
              {new_item :: map, new_state :: map}
              | {false, new_state :: map}

  @callback run(item :: map, state :: map(), args :: list(any())) ::
              {new_item :: map, new_state :: map}
              | {false, new_state :: map}
  @optional_callbacks run: 3
end
