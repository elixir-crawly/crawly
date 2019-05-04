defmodule Crawly.RequestsStorage.Worker do
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

  defstruct requests: [], count: 0, seen_fingerprints: [], spider_name: nil

  alias Crawly.RequestsStorage.Worker

  def store(pid, requests) when is_list(requests) do
    Enum.each(requests, fn request -> store(pid, request) end)
  end

  def store(pid, request), do: GenServer.call(pid, {:store, request})

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  def start_link(spider_name) do
    Logger.info("Starting requests storage worker for #{spider_name}...")

    GenServer.start_link(__MODULE__, spider_name)
  end

  def init(spider_name) do
    {:ok, %Worker{requests: [], spider_name: spider_name}}
  end

  # Store the given request
  def handle_call({:store, request}, _from, %{requests: requests} = state) do
    middlewares = Application.get_env(:crawly, :middlewares, [])

    new_state =
      case Crawly.Utils.pipe(middlewares, request, state) do
        {false, new_state} ->
          new_state

        {new_request, new_state} ->
          # Process request here....
          %{new_state | requests: [new_request | requests]}
      end

    {:reply, :ok, new_state}
  end

  # Get current request from the storage
  def handle_call(:pop, _from, state) do
    %Worker{requests: requests, count: cnt} = state

    {request, rest, new_cnt} =
      case requests do
        [] -> {nil, [], 0}
        [request] -> {request, [], 0}
        [request | rest] -> {request, rest, cnt - 1}
      end

    {:reply, request, %Worker{state | requests: rest, count: new_cnt}}
  end
end
