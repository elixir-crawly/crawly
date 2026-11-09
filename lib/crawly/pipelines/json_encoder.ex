defmodule Crawly.Pipelines.JSONEncoder do
  @moduledoc """
  Encodes a given item (map) into JSON

  No options are available for this pipeline.

  ### Example Declaration
  ```
  pipelines: [
    Crawly.Pipelines.JSONEncoder
  ]
  ```

  ### Example Usage
  ```
    iex> JSONEncoder.run(%{my: "field"}, %{})
    {"{\"my\":\"field\"}", %{}}
  ```
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state, _opts \\ []) do
    new_item = JSON.encode!(item)

    {new_item, state}
  rescue
    exception ->
      Logger.error(
        "Could not encode the following item: #{inspect(item)} into json,
          reason: #{inspect(exception)}"
      )

      {false, state}
  end
end
