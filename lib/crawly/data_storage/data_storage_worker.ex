defmodule Crawly.DataStorage.Worker do
  @moduledoc """
  A worker process which stores items for individual spiders. All items
  are pre-processed by item_pipelines.

  All pipelines are using the state of this process for their internal needs
  (persistancy).

  The DataStorage.Worker will not write anything to a filesystem. Instead it
  would expect that pipelines are going to do that work.
  """
  alias Crawly.DataStorage.Worker
  require Logger

  use GenServer

  defstruct stored_items: 0, spider_name: nil, pipeline: nil

  def start_link(spider_name: spider_name) do
    GenServer.start_link(__MODULE__, spider_name: spider_name)
  end

  @spec stats(pid()) :: {:stored_items, non_neg_integer()}
  def stats(pid), do: GenServer.call(pid, :stats)

  @spec store(pid(), map()) :: :ok
  def store(pid, item) do
    GenServer.cast(pid, {:store, item})
  end

  def init(spider_name: spider_name) do

    pipeline = pipeline_from_config(spider_name)

    {:ok, %Worker{spider_name: spider_name, pipeline: pipeline}}
  end

  def handle_cast({:store, item}, state) do
    %{ pipeline: pipeline } = state
    
    state =
      case Crawly.Utils.pipe(pipeline, item, state) do
        {false, new_state} ->
          new_state

        {_new_item, new_state} ->
          %Worker{new_state | stored_items: state.stored_items + 1}
      end

    {:noreply, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, {:stored_items, state.stored_items}, state}
  end

  defp pipeline_from_config(spider_name) do
    pipeline_from_config_entry(Application.get_env(:crawly, :pipelines, []), spider_name) || []
  end

  defp pipeline_from_config_entry(%{} = mappings, spider_name) do
    case mappings |> Map.get(spider_name) || mappings |> Map.get(:default) do
      nil -> []
      list when is_list(list) -> list
    end
  end
  defp pipeline_from_config_entry(list, _spider_name) when is_list(list), do: list
end
