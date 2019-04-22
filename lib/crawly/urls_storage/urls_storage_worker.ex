defmodule Crawly.URLStorage.Worker do
  @moduledoc """
  URLS Storage, a module responsible for storing urls for crawling
  """

  @doc """
  Storing URL

  ## Examples

      iex> Crawly.URLStorage.store_url
      :ok

  """

  require Logger

  use GenServer

  defstruct urls: [], count: 0, seen_fingerprints: []

  alias Crawly.URLStorage.Worker

  def store(pid, urls) when is_list(urls) do
    Enum.each(urls, fn url -> store(pid, url) end)
  end

  def store(pid, url), do: GenServer.call(pid, {:store, url})

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  def start_link([]) do
    Logger.info("Starting URLS storage worker...")

    GenServer.start_link(__MODULE__, [])
  end

  def init(_args) do
    Process.send_after(self(), :info, 5000)
    {:ok, %Worker{urls: []}}
  end

  def handle_call({:store, url}, _from, state) do
    %{count: cnt, urls: urls, seen_fingerprints: seen_fingerprints} = state
    fp = UUID.uuid3(:url, url)

    new_state =
      case fp in seen_fingerprints do
        false ->
          new_fingerptins = [fp | seen_fingerprints]

          new_state = %Worker{
            state
            | urls: [url | urls],
              count: cnt + 1,
              seen_fingerprints: new_fingerptins
          }

        true ->
          state
      end

    {:reply, :ok, new_state}
  end

  def handle_call(:pop, _from, state = %Worker{urls: urls, count: cnt}) do
    {url, rest, cnt} =
      case urls do
        [] -> {nil, [], 0}
        [url] -> {url, [], 0}
        [url | rest] -> {url, rest, cnt - 1}
      end

    {:reply, url, %Worker{state | urls: rest, count: cnt}}
  end

  def handle_info(:info, state) do
    Process.send_after(self(), :info, 5000)
    {:noreply, state}
  end
end
