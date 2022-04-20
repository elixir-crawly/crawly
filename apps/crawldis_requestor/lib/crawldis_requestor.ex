defmodule CrawldisRequestor do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end
  @impl true
  def init(_) do
    Logger.info("Requestor started")
    {:ok,[]}
  end
end
