defmodule Crawly.Pipelines.Validate do
  require Logger

  def run(item, state) do
    fields = Application.get_env(:crawly, :item, [])

    case Enum.all?(fields, fn key -> Map.has_key?(item, key) end) do
      false ->
        Logger.info(
          "Dropping item: #{inspect(item)}. Reason: missing required fields"
        )

        {false, state}

      _ ->
        {item, state}
    end
  end
end
