defmodule Crawly.Pipelines.Validate do
  @moduledoc """
  Ensure that scraped item contains all fields defined in config: item.
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state) do
    fields = Application.get_env(:crawly, :item, [])

    validation_result =
      fields
      |> Enum.map(fn field ->
        case Map.get(item, field) do
          val when val == nil or val == :undefined or val == "" ->
            :invalid

          _ ->
            :valid
        end
      end)
      |> Enum.uniq()

    case validation_result do
      [:valid] ->
        {item, state}

      _ ->
        Logger.info(
          "Dropping item: #{inspect(item)}. Reason: missing required fields"
        )

        {false, state}
    end
  end
end
