defmodule Crawly.Pipelines.CSVEncoder do
  @moduledoc """
  Encodes a given item (map) into CSV
  """
  @behaviour Crawly.Pipeline

  @impl Crawly.Pipeline
  def run(item, state) do
    case Application.get_env(:crawly, :item) do
      :undefined ->
        {false, state}

      fields ->
        new_item =
          Enum.reduce(fields, "", fn
            field, "" ->
              "#{inspect(Map.get(item, field, ""))}"

            field, acc ->
              acc <> "," <> "#{inspect(Map.get(item, field, ""))}"
          end)

        {new_item, state}
    end
  end
end
