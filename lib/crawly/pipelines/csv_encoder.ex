defmodule Crawly.Pipelines.CSVEncoder do
  @moduledoc """
  Encodes a given item (map) into CSV. Does not flatten nested maps.
  ### Options
  If no fields are given, the item is dropped from the pipeline.
  - `:fields`, required: The fields to extract out from the scraped item. Falls back to the global config `:item`.

  ### Example Usage
    iex> item = %{my: "first", other: "second", ignore: "this_field"}
    iex> Crawly.Pipelines.CSVEncoder.run(item, %{}, fields: [:my, :other])
    {"first,second", %{}}
  """
  @behaviour Crawly.Pipeline
  require Logger

  @impl Crawly.Pipeline
  @spec run(map, map, fields: list(atom)) ::
          {false, state :: map} | {csv_line :: String.t(), state :: map}
  def run(item, state, opts \\ []) do
    opts = Enum.into(opts, %{fields: nil})
    case opts[:fields] do
      fields when fields in [nil, []] ->
        Logger.error(
          "Dropping item: #{inspect(item)}. Reason: No fields declared for CSVEncoder"
        )

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
