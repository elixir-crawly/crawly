defmodule Crawly.URLStorage do
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

  alias Crawly.URLStorage

  def store(spider_name, urls) when is_list(urls) do
    GenServer.call(__MODULE__, {:store, {spider_name, urls}})
  end

  def store(spider_name, url) do
    store(spider_name, [url])
  end

  def pop(spider_name) do
    GenServer.call(__MODULE__, {:pop, spider_name})
  end

  def start_link([]) do
    Logger.info("Starting URLS manager...")

    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %URLStorage{}}
  end

  def handle_call({:store, {spider_name, urls}}, _from, state) do
    %{workers: workers} = state

    {worker_pid, new_workers} =
      case Map.get(workers, spider_name) do
        nil ->
          {:ok, pid} =
            DynamicSupervisor.start_child(
              Crawly.URLStorage.WorkersSup,
              Crawly.URLStorage.Worker
            )

          {pid, Map.put(workers, spider_name, pid)}

        pid ->
          {pid, workers}
      end

    Crawly.URLStorage.Worker.store(worker_pid, urls)
    {:reply, :ok, %URLStorage{state | workers: new_workers}}
  end

  def handle_call({:pop, spider_name}, _from, state = %{workers: workers}) do
    resp =
      case Map.get(workers, spider_name) do
        nil ->
          {:error, :no_worker_registered}

        pid ->
          Crawly.URLStorage.Worker.pop(pid)
      end

    {:reply, resp, state}
  end
end
