defmodule CrawldisCommon.Requestor.Worker do
  use GenServer
  alias CrawldisCommon.RequestQueue
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    send(self(), :loop)
    {:ok, %{}}
  end

  def handle_info(:loop, state) do

    case RequestQueue.pop_claimed_request() do
      {:ok, request} ->
        Logger.info("Popped claimed request for #{inspect(request.url)}")
        # do work
        # claim next one
        RequestQueue.claim_request()
      {:error, :no_claimed} ->
        # claim next one
      RequestQueue.claim_request()
      {:error, :queue_empty} ->
        Logger.debug("Queue empty, doing nothing")
        # check if there is outstanding work
      {:error, _} = err->
        Logger.error("Unknown error when popping claimed request: #{inspect(err)}")


    end

    Process.send_after(self(), :loop, 600)
    {:noreply, state}
  end
end
