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

  defstruct stored_items: 0, spider_name: nil

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
    {:ok, %Worker{spider_name: spider_name}}
  end

  def handle_cast({:store, item}, state) do
    pipelines = Crawly.Utils.get_settings(:pipelines, state.spider_name, [])

    state =
      case Crawly.Utils.pipe(pipelines, item, state) do
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
end
