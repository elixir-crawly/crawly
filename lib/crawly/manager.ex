defmodule Crawly.Manager do
  @moduledoc """
  Crawler manager module

  This module is responsible for spawning all processes related to
  a given Crawler.

  The manager spawns the following processes tree.
  ┌────────────────┐        ┌───────────────────┐
  │ Crawly.Manager ├────────> Crawly.ManagerSup │
  └────────────────┘        └─────────┬─────────┘
           │                          |
           │                          |
           ┌──────────────────────────┤
           │                          │
           │                          │
  ┌────────▼───────┐        ┌─────────▼───────┐
  │    Worker1     │        │    Worker2      │
  └────────┬───────┘        └────────┬────────┘
           │                         │
           │                         │
           │                         │
           │                         │
  ┌────────▼─────────┐    ┌──────────▼───────────┐
  │Crawly.DataStorage│    │Crawly.RequestsStorage│
  └──────────────────┘    └──────────────────────┘
  """
  require Logger

  @timeout 60_000

  use GenServer

  def start_link(spider_name) do
    Logger.debug("Starting the manager for #{spider_name}")
    GenServer.start_link(__MODULE__, spider_name)
  end

  def init(spider_name) do
    # Getting spider start urls
    [start_urls: urls] = spider_name.init()

    # Start DataStorage worker
    {:ok, data_storage_pid} = Crawly.DataStorage.start_worker(spider_name)
    Process.link(data_storage_pid)

    # Start RequestsWorker for a given spider
    {:ok, request_storage_pid} =
      Crawly.RequestsStorage.start_worker(spider_name)

    Process.link(request_storage_pid)

    # Store start requests
    requests = Enum.map(urls, fn url -> Crawly.Request.new(url) end)

    :ok = Crawly.RequestsStorage.store(spider_name, requests)

    # Start workers
    num_workers =
      Application.get_env(:crawly, :concurrent_requests_per_domain, 4)

    worker_pids =
      Enum.map(1..num_workers, fn _x ->
        DynamicSupervisor.start_child(
          spider_name,
          {Crawly.Worker, [spider_name]}
        )
      end)

    Logger.debug(
      "Started #{Enum.count(worker_pids)} workers for #{spider_name}"
    )

    # Schedule basic service operations for given spider manager
    tref = Process.send_after(self(), :operations, get_timeout())
    {:ok, %{name: spider_name, tref: tref, prev_scraped_cnt: 0}}
  end

  def handle_info(:operations, state) do
    Process.cancel_timer(state.tref)

    # Close spider if required items count was reached.
    {:stored_items, items_count} = Crawly.DataStorage.stats(state.name)

    delta = items_count - state.prev_scraped_cnt
    Logger.info("Current crawl speed is: #{delta} items/min")

    case Application.get_env(:crawly, :closespider_itemcount, :disabled) do
      :disabled ->
        :ignored

      cnt when cnt < items_count ->
        Logger.info(
          "Stopping #{inspect(state.name)}, closespider_itemcount achieved"
        )

        Crawly.Engine.stop_spider(state.name)

      _ ->
        :ignoring
    end

    # Close spider in case if it's not scraping itms fast enough
    case Application.get_env(:crawly, :closespider_timeout) do
      :undefined ->
        :ignoring

      cnt when cnt > delta ->
        Logger.info(
          "Stopping #{inspect(state.name)}, itemcount timeout achieved"
        )

        Crawly.Engine.stop_spider(state.name)

      _ ->
        :ignoring
    end

    tref = Process.send_after(self(), :operations, get_timeout())

    {:noreply, %{state | tref: tref, prev_scraped_cnt: items_count}}
  end

  defp get_timeout() do
    Application.get_env(:crawly, :manager_operations_timeout, @timeout)
  end
end
