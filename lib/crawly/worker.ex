defmodule Crawly.Worker do
  @moduledoc """
  A worker process

  """
  require Logger

  @default_backoff 1000

  defstruct backoff: 1000, spider_name: nil, base_url: nil

  use GenServer

  def start_link([spider_name, base_url]) do
    Logger.info("Starting worker #{inspect(spider_name)}")

    GenServer.start_link(__MODULE__, [spider_name, base_url])
  end

  def init([spider_name, base_url]) do
    Process.send_after(self(), :work, 2_000)

    {:ok, %{spider_name: spider_name, backoff: 2000, base_url: base_url}}
  end

  def handle_info(:work, state) do
    %{spider_name: spider_name, backoff: backoff, base_url: _base_url} = state

    new_backoff =
      case Crawly.RequestsStorage.pop(spider_name) do
        nil ->
          # Slow down a bit when there are no new URLs
          backoff * 2

        request ->
          {:ok, response} = HTTPoison.get(request.url, request.headers)

          spider_response = spider_name.parse_item(response)
          requests = Map.get(spider_response, :requests, [])
          items = Map.get(spider_response, :items, [])

          # Process all requests one by one
          Enum.each(requests, fn request ->
            request = Map.put(request, :prev_response, response)
            Crawly.RequestsStorage.store(spider_name, request)
          end)

          # Process all items one by one
          Enum.each(items, fn item ->
            Crawly.DataStorage.store(spider_name, item)
          end)

          @default_backoff
      end

    Process.send_after(self(), :work, new_backoff)
    {:noreply, %{state | backoff: new_backoff}}
  end
end
