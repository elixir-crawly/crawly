defmodule Crawly.Manager do
  @moduledoc """
  Crawler manager module

  This module is responsible from spawning all processes related to
  a given Crawler.

  The manager spawns the following processes tree.
  ┌────────────────┐        ┌───────────────────┐
  │ Crawly.Manager ├────────> Crawly.ManagerSup │
  └────────────────┘        └─────────┬─────────┘
           │                          |
           │                          |
           ┌──────────────────────────┤
           │                          │
           │                          │
  ┌────────▼───────┐        ┌─────────▼───────┐
  │    Worker1     │        │    Worker2      │
  └────────┬───────┘        └────────┬────────┘
           │                         │
           │                         │
           │                         │
           │                         │
  ┌────────▼─────────┐    ┌──────────▼───────────┐
  │Crawly.DataStorage│    │Crawly.RequestsStorage│
  └──────────────────┘    └──────────────────────┘
  """
  require Logger

  @timeout 60_000
  @start_request_split_size 50

  use GenServer

  alias Crawly.{Utils, Manager}

  defstruct template: nil,
            name: nil,
            crawl_id: nil,
            itemcount_limit: nil,
            closespider_timeout_limit: nil,
            tref: nil,
            prev_scraped_cnt: 0,
            workers: nil

  @type t :: %__MODULE__{
          template: module(),
          name: String.t(),
          crawl_id: String.t(),
          itemcount_limit: integer(),
          closespider_timeout_limit: integer(),
          tref: integer(),
          prev_scraped_cnt: integer(),
          workers: [pid()]
        }

  # a nested map
  @doc """
  Obtains the `:via` name of given spider's manager from the `Crawly.Engine.ManagerPoolRegistry`
  """
  @spec manager_via(String.t()) :: nil | term()
  def manager_via(spider_name),
    do: {:via, Registry, {Crawly.Engine.ManagerRegistry, spider_name}}

  @doc """
  Obtains the `:via` name of given spider's worker pool from the `Crawly.Engine.WorkerPoolRegistry`
  """
  @spec worker_pool_via(String.t()) :: nil | term()
  def worker_pool_via(spider_name),
    do: {:via, Registry, {Crawly.Engine.WorkerPoolRegistry, spider_name}}

  @doc """
  Obtains the PID of a given spider's manager
  """
  @spec manager_pid(String.t()) :: nil | pid()
  def manager_pid(name),
    do:
      Registry.lookup(Crawly.Engine.ManagerRegistry, name)
      |> registry_lookup_result()

  @doc """
  Obtains the PID of a given spider's worker pool
  """
  @spec worker_pool_pid(String.t()) :: nil | pid()
  def worker_pool_pid(name),
    do:
      Registry.lookup(Crawly.Engine.WorkerPoolRegistry, name)
      |> registry_lookup_result()

  # format the result of Registry.Lookup
  defp registry_lookup_result([]), do: nil
  defp registry_lookup_result([{pid, _result} | _]), do: pid

  @doc """
  Syncronously adds workers to a spider's worker pool.
  """
  @spec add_workers(module(), non_neg_integer()) ::
          :ok | {:error, :spider_not_found}
  def add_workers(spider_name, num_of_workers) do
    case manager_pid(spider_name) do
      {:error, reason} ->
        {:error, reason}

      nil ->
        {:error, :spider_not_found}

      pid ->
        GenServer.call(pid, {:add_workers, num_of_workers})
    end
  end

  @doc """
  Syncronously obtains the manager's state from a given spider.
  """
  @spec get_state(String.t()) ::
          __MODULE__.t() | {:error, :spider_not_found}
  def get_state(spider_name) do
    case manager_pid(spider_name) do
      nil ->
        {:error, :spider_not_found}

      pid ->
        GenServer.call(pid, :get_state)
    end
  end

  def start_link([spider_template, options]) do
    spider_name = Keyword.get(options, :name)

    GenServer.start_link(__MODULE__, [spider_template, options],
      name: manager_via(spider_name)
    )
  end

  @impl true
  def init([spider_template, options]) do
    crawl_id = Keyword.get(options, :crawl_id)
    spider_name = Keyword.get(options, :name)
    Logger.debug("Starting the manager from #{spider_name}")

    Logger.metadata(
      spider_name: spider_name,
      spider_template: spider_template,
      crawl_id: crawl_id
    )

    {:ok,
     %Manager{
       template: spider_template,
       name: spider_name,
       crawl_id: crawl_id
     }, {:continue, {:config, options}}}
  end

  @impl true
  def handle_continue(
        {:config, options},
        %{name: spider_name} = state
      ) do
    itemcount_limit =
      Keyword.get(
        options,
        :closespider_itemcount,
        get_default_limit(:closespider_itemcount, spider_name)
      )

    closespider_timeout_limit =
      Keyword.get(
        options,
        :closespider_timeout,
        get_default_limit(:closespider_timeout, spider_name)
      )

    # Schedule basic service operations from given spider manager
    timeout =
      Utils.get_settings(:manager_operations_timeout, spider_name, @timeout)

    tref = Process.send_after(self(), :operations, timeout)

    {:noreply,
     %{
       state
       | itemcount_limit: itemcount_limit,
         closespider_timeout_limit: closespider_timeout_limit,
         tref: tref
     }, {:continue, {:start_workers, options}}}
  end

  @impl true
  def handle_continue(
        {:start_workers, options},
        %{crawl_id: crawl_id, name: spider_name, template: spider_template} =
          state
      ) do
    # Start DataStorage worker
    case Crawly.DataStorage.start_worker(spider_name, crawl_id) do
      {:ok, data_storage_pid} ->
        Process.link(data_storage_pid)

      {:error, :already_started} ->
        :ignore
    end

    # Start RequestsWorker from a given spider
    case Crawly.RequestsStorage.start_worker(spider_name, crawl_id) do
      {:ok, request_storage_pid} ->
        Process.link(request_storage_pid)

      {:error, :already_started} ->
        :ignore
    end

    # Start workers
    num_workers =
      Keyword.get(
        options,
        :concurrent_requests_per_domain,
        Utils.get_settings(:concurrent_requests_per_domain, spider_name, 4)
      )

    registry_name = worker_pool_via(spider_name)

    worker_pids =
      Enum.map(1..num_workers, fn _x ->
        DynamicSupervisor.start_child(
          registry_name,
          {Crawly.Worker,
           [
             spider_name: spider_name,
             crawl_id: crawl_id
           ]}
        )
      end)

    Logger.debug(
      "Started #{Enum.count(worker_pids)} workers from #{spider_name} (#{
        spider_template
      })"
    )

    {:noreply,
     %{
       state
       | workers: worker_pids
     }, {:continue, {:start_requests, options}}}
  end

  @impl true
  def handle_continue({:start_requests, options}, state) do
    # Add start requests to the requests storage
    init = state.template.init(options)

    start_requests_from_req = Keyword.get(init, :start_requests, [])

    start_requests_from_urls =
      init
      |> Keyword.get(:start_urls, [])
      |> Crawly.Utils.requests_from_urls()

    start_requests = start_requests_from_req ++ start_requests_from_urls

    # Split start requests, so it's possible to initialize a part of them in async
    # manner
    {start_req, async_start_req} =
      Enum.split(start_requests, @start_request_split_size)

    :ok = do_store_requests(state.name, start_req)

    Task.start(fn ->
      do_store_requests(state.name, async_start_req)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add_workers, num_of_workers}, _from, state) do
    Logger.info("Adding #{num_of_workers} workers from #{state.name}")

    worker_pool_name = worker_pool_via(state.name)

    Enum.each(1..num_of_workers, fn _ ->
      DynamicSupervisor.start_child(
        worker_pool_name,
        {Crawly.Worker, [spider_name: state.name, crawl_id: state.crawl_id]}
      )
    end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:operations, state) do
    Process.cancel_timer(state.tref)

    # Close spider if required items count was reached.
    {:stored_items, items_count} = Crawly.DataStorage.stats(state.name)

    delta = items_count - state.prev_scraped_cnt

    Logger.info("Current crawl speed is: #{delta} items/min")

    maybe_stop_spider_by_itemcount_limit(
      state.name,
      items_count,
      state.itemcount_limit
    )

    # Close spider in case if it's not scraping items fast enough
    maybe_stop_spider_by_timeout(
      state.name,
      delta,
      state.closespider_timeout_limit
    )

    tref =
      Process.send_after(
        self(),
        :operations,
        Utils.get_settings(:manager_operations_timeout, state.name, @timeout)
      )

    {:noreply, %{state | tref: tref, prev_scraped_cnt: items_count}}
  end

  defp maybe_stop_spider_by_itemcount_limit(
         spider_name,
         current,
         limit
       )
       when current >= limit do
    Logger.info(
      "Stopping #{inspect(spider_name)}, closespider_itemcount achieved"
    )

    Crawly.Engine.stop_spider(spider_name, :itemcount_limit)
  end

  defp maybe_stop_spider_by_itemcount_limit(_, _, _), do: :ok

  defp maybe_stop_spider_by_timeout(spider_name, current, limit)
       when current <= limit and is_integer(limit) do
    Logger.info("Stopping #{inspect(spider_name)}, itemcount timeout achieved")

    Crawly.Engine.stop_spider(spider_name, :itemcount_timeout)
  end

  defp maybe_stop_spider_by_timeout(_, _, _), do: :ok

  defp maybe_convert_to_integer(value) when is_atom(value), do: value

  defp maybe_convert_to_integer(value) when is_binary(value),
    do: String.to_integer(value)

  defp maybe_convert_to_integer(value) when is_integer(value), do: value

  defp do_store_requests(spider_name, requests) do
    Enum.each(
      requests,
      fn request ->
        Crawly.RequestsStorage.store(spider_name, request)
      end
    )
  end

  # Get a closespider_itemcount or closespider_timeout_limit from config or spider
  # settings.
  defp get_default_limit(limit_name, spider_name) do
    limit_name
    |> Utils.get_settings(spider_name)
    |> maybe_convert_to_integer()
  end
end
