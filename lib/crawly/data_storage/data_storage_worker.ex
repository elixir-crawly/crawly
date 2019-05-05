defmodule Crawly.DataStorage.Worker do
  require Logger

  use GenServer

  def start_link(spider_name: spider_name) do
    GenServer.start_link(__MODULE__, spider_name: spider_name)
  end

  def store(pid, item) do
    GenServer.cast(pid, {:store, item})
    Logger.info("Storing item: #{inspect(pid)}/#{inspect(item)}")
  end

  def init(spider_name: spider_name) do
    base_path = Application.get_env(:crawly, :base_store_path, "/tmp/")

    {:ok, fd} =
      File.open("#{base_path}#{inspect(spider_name)}.json", [
        :binary,
        :write,
        :delayed_write
      ])

    {:ok, %{fd: fd}}
  end

  def handle_cast({:store, item}, state) do
    pipelines = Application.get_env(:crawly, :pipelines, [])

    state =
      case Crawly.Utils.pipe(pipelines, item, state) do
        {false, new_state} ->
          new_state

        {new_item, new_state} ->
          IO.write(state.fd, Poison.encode!(new_item))
          new_state
      end

    {:noreply, state}
  end

end
