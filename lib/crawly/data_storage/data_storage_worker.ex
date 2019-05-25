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

  defstruct fd: nil, stored_items: 0

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

    # Specify a path where items are stored on filesystem
    base_path = Application.get_env(:crawly, :base_store_path, "/tmp/")

    # Open file descriptor to write items
    {:ok, fd} =
      File.open("#{base_path}#{inspect(spider_name)}.jl", [
        :binary,
        :write,
        :delayed_write,
        :utf8
      ])

    {:ok, %Worker{fd: fd}}
  end

  def handle_cast({:store, item}, state) do
    pipelines = Application.get_env(:crawly, :pipelines, [])

    state =
      case Crawly.Utils.pipe(pipelines, item, state) do
        {false, new_state} ->
          new_state

        {new_item, new_state} ->
          write_item(state.fd, new_item)
          %Worker{new_state | stored_items: state.stored_items + 1}
      end

    {:noreply, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, {:stored_items, state.stored_items}, state}
  end

  def handle_info({:'EXIT', _from, _reason}, state) do
    File.close(state.fd)
    {:stop, :normal, state}
  end

  defp write_item(fd, item) when is_binary(item) do
    do_write_item(fd, item)
  end

  defp write_item(fd, item) do
    do_write_item(fd, Kernel.inspect(item))
  end

  defp do_write_item(fd, item) do
    try do
      IO.write(fd, item)
      IO.write(fd, "\n")

      Logger.debug(fn -> "Scraped #{inspect(item)}" end)
    catch
      error, reason ->
        stacktrace = :erlang.get_stacktrace()
        Logger.error(
          "Could not write item: #{inspect(error)}, reason: #{
            inspect(reason)}, stacktrace: #{inspect(stacktrace)}
          "
        )
    end
  end
end
