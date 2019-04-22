defmodule Crawly.DataStorage.Worker do
  require Logger

  use GenServer

  def start_link(spider_name: spider_name) do
    IO.puts("Spider name: #{inspect(spider_name)}")
    GenServer.start_link(__MODULE__, spider_name: spider_name)
  end

  def store(pid, item) do
    GenServer.cast(pid, {:store, item})
    Logger.info("Storing item: #{inspect(pid)}/#{inspect(item)}")
  end

  def init([spider_name: spider_name]) do
    {:ok, fd} =
      File.open("/tmp/#{inspect(spider_name)}.json", [
        :binary,
        :write,
        :delayed_write
      ])

    {:ok, %{fd: fd}}
  end

  def handle_cast({:store, item}, state) do
    IO.write(state.fd, Poison.encode!(item))
    {:noreply, state}
  end
end
