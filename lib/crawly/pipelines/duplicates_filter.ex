defmodule Crawly.Pipelines.DuplicatesFilter do
  @moduledoc """
  Filters out duplicated items (helps to avoid storing duplicates)

  This pipeline uses Crawly.DataStorageWorker process state in order to store
  ids of already seen items. For now they are stored only in memory.

  The field responsible for identifying duplicates is specified using
  :crawly.item_id setting.
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state) do
    item_id = Application.get_env(:crawly, :item_id)
    item_id = Map.get(item, item_id)

    case item_id do
      nil ->
        Logger.info(
          "Duplicates filter pipeline is inactive, item_id field is required
          to make it operational"
        )
        {item, state}
      _ ->
        do_run(item_id, item, state)
    end
  end

  defp do_run(item_id, item, state) do
    duplicates_filter = Map.get(state, :duplicates_filter, %{})

    case Map.has_key?(duplicates_filter, item_id) do
      false ->
        new_dups_filter = Map.put(duplicates_filter, item_id, true)
        new_state = Map.put(state, :duplicates_filter, new_dups_filter)
        {item, new_state}

      true ->
        Logger.info("[error] Duplicates filter, removed item: #{inspect(item)}")
        {false, state}
    end
  end
end
