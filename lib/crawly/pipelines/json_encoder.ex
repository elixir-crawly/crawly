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
    {JSON.encode!(item), state}
  rescue
    error ->
      Logger.error(
        "Could not encode the following item: #{inspect(item)} into json,
          reason: #{Exception.message(error)}"
      )

      {false, state}
  end
end
