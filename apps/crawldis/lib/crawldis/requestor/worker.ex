defmodule Crawldis.Requestor.Worker do
  use GenServer
  alias Crawldis.RequestQueue
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
        Logger.debug("Starting work on request: #{request.url}")
        with {:ok, request_with_response} <- do_requesting(request),
          {:ok, %{items: items, requests: new_requests}} <- do_parsing(request_with_response) do
            # send items to processors
            Logger.debug("Sending #{length(items)} to processors")
            # send requests to request queue
            Logger.debug("Sending #{length(new_requests)} to request queue")
            for new_request <- new_requests do
              RequestQueue.add_request(new_request)
            end
        else
          {:error, _}= err->
            Logger.error("Unknown error occured while making request: #{inspect(err)}")
          {:drop, request}->
            Logger.info("Dropping request: #{request.url}")
        end
        # claim next one
        RequestQueue.claim_request()
      {:error, :no_claimed} ->
        # claim next one
      RequestQueue.claim_request()
      {:error, :queue_empty} ->
        Logger.debug("Queue empty, doing nothing")
    end

    Process.send_after(self(), :loop, 600)
    {:noreply, state}
  end

  defp do_requesting(request) do
    {fetcher, options} = request.fetcher |> Crawly.Utils.unwrap_module_and_options()
    case fetcher.fetch(request, options) do
      {:ok, response}->
        {:ok, Map.put(request, :response, response)}
      other -> other
    end
  end

  defp do_parsing(request_with_response) do
    case Crawly.Utils.pipe(request_with_response.parsers, %Crawly.ParsedItem{}, %{}) do
      {false, _} ->
        {:drop, request_with_response}
      {parsed, _new_state} ->
        {:ok, parsed}
    end
  end
end
