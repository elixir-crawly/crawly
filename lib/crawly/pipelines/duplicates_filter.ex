defmodule Crawly.Pipelines.DuplicatesFilter do
  require Logger

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
