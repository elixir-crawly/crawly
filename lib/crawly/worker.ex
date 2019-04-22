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
    %{spider_name: spider_name, backoff: backoff, base_url: base_url} = state

    new_backoff =
      case Crawly.URLStorage.pop(spider_name) do
        nil ->
          # Slow down a bit when there are no new URLs
          backoff * 2

        url ->
          {:ok, response} = HTTPoison.get(url)

          case spider_name.parse_item(response) do
            {:urls, urls} ->
              new_urls =
                urls
                |> Enum.map(fn url ->
                  URI.merge(base_url, url) |> to_string()
                end)
                |> Enum.filter(fn url -> String.starts_with?(url, base_url) end)
                |> Enum.uniq()

              Crawly.URLStorage.store(spider_name, new_urls)

            {:items, items} ->
              Enum.each(items, fn item ->
                Crawly.DataStorage.store(spider_name, item)
              end)

            _ ->
              Logger.info("""
              Unxepected response from spider. Please check if it implements
              parse_item behaviour correctly!"
              """)
          end

          @default_backoff
      end

    Process.send_after(self(), :work, new_backoff)
    {:noreply, %{state | backoff: new_backoff}}
  end
end
