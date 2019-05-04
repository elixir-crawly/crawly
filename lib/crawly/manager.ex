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

    # Register a worker for a given spider
    # this is a hackish way of doing things. TODO: make register API
    Crawly.RequestsStorage.store(spider_name, %Crawly.Request{url: hd(urls)})

    {:ok, pid} =
      DynamicSupervisor.start_child(
        spider_name,
        {Crawly.Worker, [spider_name, base_url]}
      )

    Logger.info("[error] Worker pid #{inspect(pid)}")
    {:ok, %{name: spider_name}}
  end

  defp get_base_url(url) do
    struct = URI.parse(url)
    "#{struct.scheme}://#{struct.host}"
  end
end
