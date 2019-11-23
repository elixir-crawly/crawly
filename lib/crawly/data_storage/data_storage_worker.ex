defmodule Crawly.DataStorage.Worker do
  @moduledoc """
  A worker process which stores items for individual spiders. All items
  are pre-processed by item_pipelines.

  All pipelines are using the state of this process for their internal needs
  (persistancy).

  For example, it might be useful to include:
  1) DuplicatesFilter pipeline (it filters out already seen items)
  2) JSONEncoder pipeline (it converts items to JSON)
  """
  alias Crawly.DataStorage.Worker
  require Logger

  use GenServer

  defstruct io_device: nil, stored_items: 0, backend: nil

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
    Process.flag(:trap_exit, true)

    # Picking a storage backend
    storage_backend = Application.get_env(
      :crawly,
      :storage_backend,
      Crawly.DataStorage.FileStorageBackend
    )

    {:ok, io_device} = storage_backend.init(spider_name)
    {:ok, %Worker{io_device: io_device, backend: storage_backend}}
  end

  def handle_cast({:store, item}, %{backend: storage_backend} = state) do
    pipelines = Application.get_env(:crawly, :pipelines, [])

    state =
      case Crawly.Utils.pipe(pipelines, item, state) do
        {false, new_state} ->
          new_state

        {new_item, new_state} ->
          :ok = storage_backend.write(
            state.io_device,
            new_item
          )
          %Worker{new_state | stored_items: state.stored_items + 1}
      end
    {:noreply, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, {:stored_items, state.stored_items}, state}
  end

  def handle_info({:EXIT, _from, _reason}, state) do
    {:stop, :normal, state}
  end

end
