defmodule Crawly.Manager do
  @moduledoc """
  Manager module
  """
  require Logger

  use GenServer

  def start_link(spider_name) do
    IO.puts("Starting manger with given name: #{inspect(spider_name)}")

    GenServer.start_link(__MODULE__, spider_name)
  end

  def init(spider_name) do
    [start_urls: urls] = spider_name.init()

    base_url = get_base_url(hd(urls))

    Crawly.RequestsStorage.start_worker(spider_name)

    # Store start requests
    requests = Enum.map(urls, fn url ->  %Crawly.Request{url: url} end)
    Crawly.RequestsStorage.store(spider_name, requests)

    # Start workers
    num_workers =
      Application.get_env(:crawly, :concurrent_requests_per_domain, 1)

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

    {:ok, %{name: spider_name}}
  end

  defp get_base_url(url) do
    struct = URI.parse(url)
    "#{struct.scheme}://#{struct.host}"
  end
end
