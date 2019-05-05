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

  def start_worker(spider_name) do
    GenServer.call(__MODULE__, {:start_worker, spider_name})
  end

  def store(spider, item) do
    Logger.info("Stored item is: #{inspect(item)}")
    GenServer.call(__MODULE__, {:store, spider, item})
  end

  def stats(spider) do
    GenServer.call(__MODULE__, {:stats, spider})
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


  def handle_call({:start_worker, spider_name}, _from, state) do
    {msg, new_workers} =
      case Map.get(state.workers, spider_name) do
        nil ->
          {:ok, pid} =
            DynamicSupervisor.start_child(
              Crawly.DataStorage.WorkersSup,
              {Crawly.DataStorage.Worker, [spider_name: spider_name]})

          {pid, Map.put(state.workers, spider_name, pid)}
        _ ->
          {{:error, :already_started}, state.workers}
      end
    {:reply, msg, %{state | workers: new_workers}}
  end

  def handle_call({:stats, spider_name}, _from, state) do
    msg =
      case Map.get(state.workers, spider_name) do
        nil ->
          {:error, :data_storage_worker_not_running}

        pid ->
          Crawly.DataStorage.Worker.stats(pid)
      end

    {:reply, msg, state}
  end
end
