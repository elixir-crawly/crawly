defmodule Crawly.Pipelines.JSONEncoder do
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state) do
    case Poison.encode(item) do
      {:ok, new_item} ->
        {new_item, state}

      {:error, reason} ->
        Logger.info(
          "Could not encode the following item: #{inspect(item)} into json,
          reason: #{inspect(reason)}"
        )

        {false, state}
    end
  end
end
