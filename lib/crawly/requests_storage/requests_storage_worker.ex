defmodule Crawly.RequestsStorage.Worker do
  @moduledoc """
  Requests Storage, is a module responsible for storing requests for a given
  spider.

  Automatically filters out already seen requests (uses `fingerprints` approach
  to detect already visited pages).

  Pipes all requests through a list of middlewares, which do pre-processing of
  all requests before storing them
  """
  require Logger

  use GenServer

  defstruct requests: [], count: 0, spider_name: nil

  alias Crawly.RequestsStorage.Worker

  @doc """
  Store requests
  """
  @spec store(spider_name, requests) :: :ok
        when spider_name: atom(),
             requests: [Crawly.Request.t()]
  def store(pid, requests) when is_list(requests) do
    Enum.each(requests, fn request -> store(pid, request) end)
  end

  @doc """
  Store individual request request
  """
  @spec store(spider_name, request) :: :ok
        when spider_name: atom(),
             request: Crawly.Request.t()
  def store(pid, request), do: GenServer.call(pid, {:store, request})

  @doc """
  Pop a request out of requests storage
  """
  @spec pop(pid()) :: Crawly.Request.t() | nil
  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  @doc """
  Get statistics from the requests storage
  """
  @spec stats(pid()) :: {:stored_requests, non_neg_integer()}
  def stats(pid) do
    GenServer.call(pid, :stats)
  end

  def start_link(spider_name) do
    Logger.debug("Starting requests storage worker for #{spider_name}...")

    GenServer.start_link(__MODULE__, spider_name)
  end

  def init(spider_name) do
    {:ok, %Worker{requests: [], spider_name: spider_name}}
  end

  # Store the given request
  def handle_call({:store, request}, _from, state) do
    middlewares = request.middlewares

    new_state =
      case Crawly.Utils.pipe(middlewares, request, state) do
        {false, new_state} ->
          new_state

        {new_request, new_state} ->
          # Process request here....
          %{
            new_state
            | count: state.count + 1,
              requests: [new_request | state.requests]
          }
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

  def handle_call(:stats, _from, state) do
    {:reply, {:stored_requests, state.count}, state}
  end
end
