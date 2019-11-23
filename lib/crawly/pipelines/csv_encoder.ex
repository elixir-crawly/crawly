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

      headers ->
        {Crawly.Utils.list_to_csv(headers, item), state}
    end
  end
end
