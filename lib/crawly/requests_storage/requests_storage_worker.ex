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

  defstruct requests: [], count: 0, spider_name: nil, crawl_id: nil

  alias Crawly.RequestsStorage.Worker

  @doc """
  Store individual request or multiple requests
  """
  @spec store(Crawly.spider(), Crawly.Request.t() | [Crawly.Request.t()]) :: :ok
  def store(pid, %Crawly.Request{} = request), do: store(pid, [request])

  def store(pid, requests) when is_list(requests) do
    do_call(pid, {:store, requests})
  end

  @doc """
  Pop a request out of requests storage
  """
  @spec pop(pid()) :: Crawly.Request.t() | nil
  def pop(pid) do
    do_call(pid, :pop)
  end

  @doc """
  Get statistics from the requests storage
  """
  @spec stats(pid()) :: {:stored_requests, non_neg_integer()}
  def stats(pid) do
    do_call(pid, :stats)
  end

  def start_link(spider_name, crawl_id) do
    GenServer.start_link(__MODULE__, [spider_name, crawl_id])
  end

  def init([spider_name, crawl_id]) do
    Logger.metadata(spider_name: spider_name, crawl_id: crawl_id)

    Logger.debug(
      "Starting requests storage worker for #{inspect(spider_name)}..."
    )

    {:ok, %Worker{requests: [], spider_name: spider_name, crawl_id: crawl_id}}
  end

  # Store the given requests
  def handle_call({:store, requests}, _from, state) do
    new_state = Enum.reduce(requests, state, &pipe_request/2)
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

  defp do_call(pid, command) do
    GenServer.call(pid, command)
  catch
    error, reason ->
      Logger.debug(Exception.format(error, reason, __STACKTRACE__))
  end

  defp pipe_request(request, state) do
    case Crawly.Utils.pipe(request.middlewares, request, state) do
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
  end
end
