defmodule Crawly.Pipelines.Experimental.Preview do
  @moduledoc """
  Allows to preview items extracted by the spider so far

  Stores previewable items under 'Elixir.Crawly.Pipelines.Experimental.Preview'

  ### Options
    - `limit`, (optional, if not provided 100 is used) - resrticts the number of items visible in preview

  Probably it's better to place it higher than CSV/JSON converters.

  ### Example usage in Crawly config
  ```
    pipelines: [
      {Crawly.Pipelines.Experimental.Preview, limit: 10},

      # As you can see we're using data transformators afterwords
      Crawly.Pipelines.JSONEncoder,
      {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"}
    ]
  ```
  """
  @behaviour Crawly.Pipeline

  # Restrict the number of items stored in state of the worker
  @limit 20

  require Logger

  @impl Crawly.Pipeline
  def run(item, state, opts \\ []) do
    preview = Map.get(state, __MODULE__, [])
    limit = Keyword.get(opts, :limit, @limit)

    case Enum.count(preview) >= limit do
      true ->
        {item, state}

      false ->
        new_preview = [item | preview]
        new_state = Map.put(state, __MODULE__, new_preview)
        {item, new_state}
    end
  end
end
