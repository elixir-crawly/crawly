defmodule Crawly.Pipelines.DuplicatesFilter do
  @moduledoc """
  Filters out duplicated items based on the provided `item_id`.

  Stores identifier values in state under the `:duplicates_filter` key.

  ### Options
  If item unique identifier is not provided, this pipeline does nothing.
  - `:item_id`, required: Designates a field to be used to check for duplicates. Falls back to global config `:item_id`.

  ### Example Usage
    ```
    iex> item = %{my: "item"}
    iex> {_unchanged, new_state} = DuplicatesFilter.run(first, %{}, item_id: :my)

    # Rerunning the item through the pipeline will drop the item
    iex> DuplicatesFilter.run(first, %{}, item_id: :id)
    {false, %{
      duplicates_filter: %{"item" => true}
    }}
    ```
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  @spec run(map, map, item_id: atom) ::
          {false, state :: map}
          | {item :: map,
             state :: %{duplicates_filter: %{required(String.t()) => boolean}}}
  def run(item, state, opts \\ []) do
    opts = Enum.into(opts, %{item_id: nil})

    item_id = Map.get(opts, :item_id)

    item_id = Map.get(item, item_id)

    case item_id do
      nil ->
        Logger.info(
          "Duplicates filter pipeline is inactive, item_id option is required
          to make it operational."
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
        Logger.debug("Duplicates filter dropped item: #{inspect(item)}")
        {false, state}
    end
  end
end
