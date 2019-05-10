defmodule Crawly.Worker do
  @moduledoc """
  A worker process

  """
  require Logger

  @default_backoff 300

  defstruct backoff: @default_backoff, spider_name: nil, base_url: nil

  use GenServer

  def start_link([spider_name, base_url]) do
    Logger.info("Starting worker #{inspect(spider_name)}")

    GenServer.start_link(__MODULE__, [spider_name, base_url])
  end

  def init([spider_name, base_url]) do
    Process.send_after(self(), :work, @default_backoff)

    state = %{
      spider_name: spider_name,
      backoff: @default_backoff,
      base_url: base_url
    }

    {:ok, state}
  end

  def handle_info(:work, state) do
    %{spider_name: spider_name, backoff: backoff, base_url: _base_url} = state

    new_backoff =
      case Crawly.RequestsStorage.pop(spider_name) do
        nil ->
          Logger.debug("No work, increase backoff to #{inspect(backoff * 2)}")
          # Slow down a bit when there are no new URLs
          backoff * 2

        request ->
          {:ok, response} =
            HTTPoison.get(request.url, request.headers, request.options)

          spider_response = spider_name.parse_item(response)
          requests = Map.get(spider_response, :requests, [])
          items = Map.get(spider_response, :items, [])


          follow_redirect = Application.get_env(:crawly, :follow_redirect, false)

          # Process all requests one by one
          Enum.each(requests, fn request ->
            request = request
            |> Map.put(:prev_response, response)
            |> Map.put(:options, [{:follow_redirect, follow_redirect}])

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
