defmodule Crawly.Manager do
  @moduledoc """
  Manager module
  """
  require Logger

  @timeout 5000

  use GenServer

  def start_link(spider_name) do
    IO.puts("Starting manger with given name: #{inspect(spider_name)}")

    GenServer.start_link(__MODULE__, spider_name)
  end

  def init(spider_name) do
    [start_urls: urls] = spider_name.init()

    Crawly.DataStorage.start_worker(spider_name)
    Crawly.RequestsStorage.start_worker(spider_name)

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
    {:ok, %{name: spider_name, tref: tref}}
  end

  def handle_info(:operations, state) do
    Process.cancel_timer(state.tref)

    tref = Process.send_after(self(), :operations, @timeout)
    Logger.info("Processing..")
    {:noreply, %{state | tref: tref}}
  end

  defp get_base_url(url) do
    struct = URI.parse(url)
    "#{struct.scheme}://#{struct.host}"
  end
end
