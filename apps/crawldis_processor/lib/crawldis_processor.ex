defmodule CrawldisProcessor do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end
  @impl true
  def init(_) do
    Logger.info("Processor started")
    ping()
    {:ok,[]}
  end

  @impl true
  def handle_info(:ping, state) do
    Logger.info("Processor is up la!")
    ping()
    {:noreply, state}
  end

  def ping do
    Process.send_after(self(), :ping, 1000)
  end
end
