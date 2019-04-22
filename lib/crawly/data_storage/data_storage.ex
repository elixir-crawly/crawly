defmodule Crawly.DataStorage do
  @moduledoc """
  URLS Storage, a module responsible for storing urls for crawling
  """

  @doc """
  Storing URL

  ## Examples

      iex> Crawly.URLStorage.store_item
      :ok

  """
  require Logger

  use GenServer

  defstruct workers: %{}

  def store(spider, item) do
    Logger.info("Stored item is: #{inspect(item)}")
    GenServer.call(__MODULE__, {:store, spider, item})
  end

  def start_link([]) do
    Logger.info("Starting data storage")

    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{workers: %{}}}
  end

  def handle_call({:store, spider, item}, _from, state) do
    Logger.info("Storing item...")
    %{workers: workers} = state

    {pid, new_workers} =
      case Map.get(workers, spider) do
        nil ->
          {:ok, pid} =
            DynamicSupervisor.start_child(
              Crawly.DataStorage.WorkersSup,
              {Crawly.DataStorage.Worker, [spider_name: spider]})

          {pid, Map.put(workers, spider, pid)}

        pid ->
          {pid, workers}
      end

    Crawly.DataStorage.Worker.store(pid, item)
    {:reply, :ok, %{state | workers: new_workers}}
  end
end
