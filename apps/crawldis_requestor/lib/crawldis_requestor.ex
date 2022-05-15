defmodule CrawldisRequestor do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("Requestor started, pid: #{inspect(self())}")

    {:ok, pid} =
      GenServer.start_link(Crawly.RequestsStorage.Worker, [
        :test_spider,
        "crawl-123"
      ])

    {:ok, %{storage_worker_pid: pid}}
  end

  def crawl(string) do
    GenServer.cast(__MODULE__, {:crawl, string})
  end

  @impl true
  def handle_cast({:crawl, start_url}, %{storage_worker_pid: pid} = state) do
    Logger.debug("Received start url #{start_url}")

    # Store the request
    # current impl: stores requests on individual workers
    request = %Crawly.Request{url: start_url}
    Crawly.RequestsStorage.Worker.store(pid, request)

    Logger.debug(
      "Storage worker post-storage stats, #{inspect(Crawly.RequestsStorage.Worker.stats(pid))}"
    )

    # process request
    popped = Crawly.RequestsStorage.Worker.pop(pid)
    result = Crawly.Worker.get_response({popped, :test_spider})

    Logger.debug(
      "Storage worker post-popped stats, #{inspect(Crawly.RequestsStorage.Worker.stats(pid))}"
    )

    Logger.debug("get_response result: #{inspect(result)}")

    # parse the result
    {:noreply, state}
  end

  # @impl true
  # def handle_info(:ping, state) do
  #   ping()
  #   {:noreply, state}
  # end

  # defp ping do
  #   # Logger.info("Connected to #{inspect(Node.list())}")
  #   Process.send_after(self(), :ping, 5000)
  # end
end
