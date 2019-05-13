defmodule Crawly.Manager do
  @moduledoc """
  Manager module
  """
  require Logger

  @timeout 30_000

  use GenServer

  def start_link(spider_name) do
    IO.puts("Starting manger with given name: #{inspect(spider_name)}")

    GenServer.start_link(__MODULE__, spider_name)
  end

  def init(spider_name) do
    [start_urls: urls] = spider_name.init()

    {:ok, data_storage_pid} = Crawly.DataStorage.start_worker(spider_name)
    Process.link(data_storage_pid)
    {:ok, request_storage_pid} = Crawly.RequestsStorage.start_worker(spider_name)
    Process.link(request_storage_pid)

    # Store start requests
    requests = Enum.map(urls, fn url ->  %Crawly.Request{url: url} end)
    Crawly.RequestsStorage.store(spider_name, requests)

    # Start workers
    num_workers =
      Application.get_env(:crawly, :concurrent_requests_per_domain, 4)

    base_url = get_base_url(hd(urls))
    worker_pids =
      Enum.map(1..num_workers, fn _x ->
        DynamicSupervisor.start_child(
          spider_name,
          {Crawly.Worker, [spider_name, base_url]}
        )
      end)

    Logger.debug(
      "Started #{Enum.count(worker_pids)} workers for #{spider_name}"
    )

    tref = Process.send_after(self(), :operations, @timeout)
    {:ok, %{name: spider_name, tref: tref, prev_scraped_cnt: 0}}
  end

  def handle_info(:operations, state) do
    Logger.info("Manager operations...")
    Process.cancel_timer(state.tref)

    # Close spider if required items count was reached.
    items_count = Crawly.DataStorage.stats(state.name)
    case Application.get_env(:crawly, :closespider_itemcount) do
      :undefined -> :ignoring
      cnt when cnt < items_count ->
        Logger.info("Stopping #{inspect(state.name)}, closespider_itemcount achieved")
        Crawly.Engine.stop_spider(state.name)
      _ ->
        :ignoring
    end

    prev_scraped_cnt = state.prev_scraped_cnt
    case Application.get_env(:crawly, :closespider_timeout) do
      :undefined -> :ignoring
      cnt when cnt > (items_count - prev_scraped_cnt) ->
        Logger.info("Stopping #{inspect(state.name)}, itemcount timeout achieved")
        Crawly.Engine.stop_spider(state.name)
      _ ->
        :ignoring
    end

    tref = Process.send_after(self(), :operations, @timeout)

    {:noreply, %{state | tref: tref, prev_scraped_cnt: items_count}}
  end

  defp get_base_url(url) do
    struct = URI.parse(url)
    "#{struct.scheme}://#{struct.host}"
  end
end
