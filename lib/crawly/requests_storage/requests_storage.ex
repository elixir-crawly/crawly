defmodule Crawly.RequestsStorage do
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

  defstruct workers: %{}

  alias Crawly.RequestsStorage

  def store(spider_name, requests) when is_list(requests) do
    GenServer.call(__MODULE__, {:store, {spider_name, requests}})
  end

  def store(spider_name, request) do
    store(spider_name, [request])
  end

  def pop(spider_name) do
    GenServer.call(__MODULE__, {:pop, spider_name})
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %RequestsStorage{}}
  end

  def handle_call({:store, {spider_name, requests}}, _from, state) do
    %{workers: workers} = state

    # Start the requests storage worker if it not started yet
    {worker_pid, new_workers} =
      case Map.get(workers, spider_name) do
        nil ->
          {:ok, pid} =
            DynamicSupervisor.start_child(
              Crawly.RequestsStorage.WorkersSup,
              {Crawly.RequestsStorage.Worker, spider_name}
            )

          {pid, Map.put(workers, spider_name, pid)}

        pid ->
          {pid, workers}
      end

    Crawly.RequestsStorage.Worker.store(worker_pid, requests)
    {:reply, :ok, %RequestsStorage{state | workers: new_workers}}
  end

  def handle_call({:pop, spider_name}, _from, state = %{workers: workers}) do
    resp =
      case Map.get(workers, spider_name) do
        nil ->
          {:error, :no_worker_registered}

        pid ->
          Crawly.RequestsStorage.Worker.pop(pid)
      end

    {:reply, resp, state}
  end
end
