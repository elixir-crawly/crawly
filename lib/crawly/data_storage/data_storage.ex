defmodule Crawly.DataStorage do
  @moduledoc """
  Data Storage, is a module responsible for storing crawled items.
  On the high level it's possible to represent the architecture of items
  storage this way:


                 ┌──────────────────┐
                 │                  │             ┌------------------┐
                 │   DataStorage    <─────────────┤ From crawlers1,2 │
                 │                  │             └------------------┘
                 └─────────┬────────┘
                           │
                           │
                           │
                           │
              ┌────────────▼─────────────────┐
              │                              │
              │                              │
              │                              │
  ┌───────────▼──────────┐       ┌───────────▼──────────┐
  │  DataStorageWorker1  │       │   DataStorageWorker2 │
  │      (Crawler1)      │       │      (Crawler2)      │
  └──────────────────────┘       └──────────────────────┘
  """
  require Logger

  use GenServer

  defstruct workers: %{}, pid_spiders: %{}

  def start_worker(spider_name, crawl_id) do
    GenServer.call(__MODULE__, {:start_worker, spider_name, crawl_id})
  end

  @spec store(atom(), map()) :: :ok
  def store(spider, item) do
    GenServer.call(__MODULE__, {:store, spider, item})
  end

  def stats(spider) do
    GenServer.call(__MODULE__, {:stats, spider})
  end

  @spec inspect(atom(), term()) ::
          {:error, :data_storage_worker_not_running} | term()
  def inspect(spider, field) do
    GenServer.call(__MODULE__, {:inspect, spider, field})
  end

  def start_link([]) do
    Logger.debug("Starting data storage")

    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %Crawly.DataStorage{workers: %{}, pid_spiders: %{}}}
  end

  def handle_call({:store, spider, item}, _from, state) do
    %{workers: workers} = state

    message =
      case Map.get(workers, spider) do
        nil ->
          {:error, :data_storage_worker_not_running}

        pid ->
          Crawly.DataStorage.Worker.store(pid, item)
      end

    {:reply, message, state}
  end

  def handle_call({:start_worker, spider_name, crawl_id}, _from, state) do
    {msg, new_state} =
      case Map.get(state.workers, spider_name) do
        nil ->
          pid = do_start_worker(spider_name, crawl_id)

          new_workers = Map.put(state.workers, spider_name, pid)
          new_spider_pids = Map.put(state.pid_spiders, pid, spider_name)

          new_state = %Crawly.DataStorage{
            state
            | workers: new_workers,
              pid_spiders: new_spider_pids
          }

          {{:ok, pid}, new_state}

        _ ->
          {{:error, :already_started}, state}
      end

    {:reply, msg, new_state}
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

  def handle_call({:inspect, spider_name, field}, _from, state) do
    msg =
      case Map.get(state.workers, spider_name) do
        nil ->
          {:error, :data_storage_worker_not_running}

        pid ->
          Crawly.DataStorage.Worker.inspect(pid, field)
      end

    {:reply, msg, state}
  end

  # Clean up worker
  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    spider_name = Map.get(state.pid_spiders, pid)
    new_pid_spiders = Map.delete(state.pid_spiders, pid)
    new_workers = Map.delete(state.workers, spider_name)
    new_state = %{state | workers: new_workers, pid_spiders: new_pid_spiders}

    {:noreply, new_state}
  end

  defp do_start_worker(spider_name, crawl_id) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Crawly.DataStorage.WorkersSup,
        %{
          id: :undefined,
          restart: :temporary,
          start:
            {Crawly.DataStorage.Worker, :start_link,
             [[spider_name: spider_name, crawl_id: crawl_id]]}
        }
      )

    Process.monitor(pid)
    pid
  end
end
