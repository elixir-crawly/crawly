defmodule Crawly.Engine do
  @moduledoc """
  Crawly Engine - process responsible for starting and stopping spiders.

  Stores information on all currently running spiders.
  """
  require Logger

  use GenServer

  @type t :: %__MODULE__{
          started_spiders: started_spiders(),
          known_spiders: [module()]
        }
  # a nested map that holds information on all started instances of the spider template
  @type started_spiders() :: %{optional(String.t()) => map()}

  @type spider_info() :: %{
          name: String.t(),
          crawl_id: String.t(),
          name: String.t(),
          pid: pid(),
          status: :initializing | :running,
          workers: nil
        }

  defstruct(started_spiders: %{}, known_spiders: [])

  @doc """
  Starts a spider asyncronously. All options passed in the second argument will be passed along to the spider's `init/1` callback. Returns `:ok` if the spider startup task has been fired correctly.

  Accepts a template module as the first positional argument.

  All spiders are referenced by a string name. This string name must be unique. Multiple spiders can utilize the same template module.

  ### Reserved Options
  - `:name` (binary). Optional. If not provided, the spider template module name will be stringified.
  - `:crawl_id` (binary). Optional, automatically generated if not set.
  - `:closespider_itemcount` (integer | disabled). Optional, overrides the close
    spider item count on startup.
  - `:closespider_timeout` (integer | disabled). Optional, overrides the close
                            spider timeout on startup.
  - `:concurrent_requests_per_domain` (integer). Optional, overrides the number of
     workers for a given spider

  ### Asyncronous Spider Startup Lifecycle
  When being started up, a spider's `:status` will begin from `:initializing`, and transition to `:running`. When `:initializing`, the spider tree will be created and start requests placed in the storage. The spider's related process name references will also be stored in the local registries.

  Once the startup is complete, the spider's `:status` will then be set to `:running`.

  ### Backward compatibility
  #### `:crawl_id` as 2nd positional argument
  If the 2nd positional argument is a binary, it will be set as the `:crawl_id`. Deprecated, will be removed in the future.
  """

  @typep crawl_id_opt :: {:crawl_id, binary()}
  @typep name_opt :: {:name, String.t()}
  @spec start_spider(spider_template, opts) :: result
        when spider_template: module(),
             opts: [crawl_id_opt() | name_opt()],
             result:
               :ok
               | {:error, :spider_already_started}
               | {:error, :atom}

  def start_spider(template) when is_atom(template),
    do: start_spider(template, [])

  def start_spider(spider_template, opts)
      when is_list(opts) and
             is_atom(spider_template) do
    opts =
      Enum.into(opts, %{})
      |> Map.put_new_lazy(:crawl_id, &UUID.uuid1/0)
      # stringify the template name
      |> Map.put_new_lazy(:name, fn -> Atom.to_string(spider_template) end)

    # Filter all logs related to a given spider
    set_spider_log(spider_template, opts[:crawl_id])

    GenServer.call(
      __MODULE__,
      {:start_spider, spider_template, opts}
    )
  end

  # TODO: Remove before major version
  def start_spider(spider_template, crawl_id, opts \\ [])
      when is_binary(crawl_id) do
    Logger.warn(
      "Deprecation Warning: Setting the crawl_id as second positional argument is deprecated. Please use the :crawl_id option instead. Refer to docs for more info (https://hexdocs.pm/crawly/Crawly.Engine.html#start_spider/2) "
    )

    args = [{:crawl_id, crawl_id} | opts]
    start_spider(spider_template, args)
  end

  @doc """
  Deprecated. Use `Crawly.Manager.manager_pid/1` instead
  """
  # TODO: Remove before major version
  @spec get_manager(module()) ::
          pid() | {:error, :spider_not_found}
  def get_manager(spider_name) do
    Logger.warn(
      "Deprecation Warning: Calling Crawly.Engine.get_manager/1 is deprecated. Please use Crawly.Manager.manager_pid/1 to obtain a manager's pid."
    )

    GenServer.call(__MODULE__, {:get_manager, spider_name})
  end

  @doc """
  Stops a spider asyncronously.

  If a string spider name is passed, the runtime spider with a matching name will be stopped.

  If a template module is passed, all runtime spiders that utilizes that spider template module will be stopped.

  An optinal second positional argument can be passed as a stop reason. This argument is passed to `on_spider_closed_callback/1` when the spider is closed.any()

  Note that the spider supervision tree will only be terminated after being fully initialized. Hence, if the spider is stopped before being fully initialized (as indicated by the spider's `:status` key), it may result in the `on_spider_closed_callback/1` being called before the spider tree is terminated.
  """
  @spec stop_spider(module() | String.t(), reason) :: result
        when reason: :itemcount_limit | :itemcount_timeout | atom(),
             result:
               :ok | {:error, :spider_not_running} | {:error, :spider_not_found}

  def stop_spider(spider_name, reason \\ :ignore) do
    GenServer.call(__MODULE__, {:stop_spider, spider_name, reason})
  end

  @doc """
  Lists all started spiders and related information.
  """
  @spec list_started_spiders() :: [spider_info()]
  def list_started_spiders() do
    GenServer.call(__MODULE__, :list_started_spiders)
  end

  @doc """
  Lists all spider template modules that implement the `Crawly.Spider` behaviour.
  """
  @spec list_spider_templates() :: [module()]
  def list_spider_templates() do
    GenServer.call(__MODULE__, :list_spider_templates)
  end

  # TODO: Remove before major version
  @doc """
  Deprecated. use `Crawly.Engine.list_started_spiders/0` instead.
  """
  @spec running_spiders() :: [spider_info()]
  def running_spiders() do
    Logger.warn(
      "Deprecation Warning: using Crawly.Engine.running_spiders/0 is deprecated and will be removed. Use Crawly.Engine.list_started_spiders/0 instead"
    )

    GenServer.call(__MODULE__, :running_spiders)
  end

  @doc """
  Retrieves a specific spider's information.

  ### Keys
  - `:name`: The spider's internally unique name.
  - `:template`: The spider template module used.
  - `:crawl_id`: The current crawl id.
  - `:status`: The spider's current status. Indicates which lifecycle stage it is currently in.
  - `:workers`: A count of the current number of workers associated with this spider.
  - `:pid`: The `pid` of the spider's supervision tree.
  """
  @spec get_spider_info(String.t() | module()) :: spider_info()
  def get_spider_info(name) when is_binary(name) do
    GenServer.call(__MODULE__, {:get_spider_info, name})
  end

  def get_spider_info(name) when is_atom(name),
    do: name |> Atom.to_string() |> get_spider_info()

  @doc """
  Refreshes the cached list of known spider template modules. This function should be run manually and infrequently, as searching for modules that implement the `Crawly.Spider` behaviour module is resource intensive and may crash the engine if over-used.
  """
  def refresh_spider_list() do
    GenServer.cast(__MODULE__, :refresh_spider_list)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Deprecated. Use `Crawly.Engine.get_spider_info/1` instead to retrieve the `:crawl_id`
  Retrieves a spider's `crawl_id`.
  """
  # TODO: Remove before major version
  @spec get_crawl_id(String.t() | module()) ::
          {:error, :spider_not_running} | {:ok, binary()}
  def get_crawl_id(spider_name) when is_binary(spider_name) do
    Logger.warn(
      "Deprecation Warning: Retrieving a spider's current crawl_id through Crawly.Engine.get_crawl_id/1 is deprecated. Please use `Crawly.Engine.get_spider_info/1` instead to retrieve a spider's current crawl_id"
    )

    GenServer.call(__MODULE__, {:get_crawl_id, spider_name})
  end

  def get_crawl_id(name) when is_atom(name) do
    GenServer.call(
      __MODULE__,
      {:get_crawl_id, Atom.to_string(name)}
    )
  end

  @spec init(any) :: {:ok, __MODULE__.t()}
  def init(_args) do
    spiders = get_updated_known_spider_list()
    {:ok, %Crawly.Engine{known_spiders: spiders}}
  end

  def handle_call({:get_manager, spider_name}, _, state) do
    pid = Crawly.Manager.manager_pid(spider_name)

    {:reply, pid, state}
  end

  def handle_call({:get_crawl_id, spider_name}, _from, state) do
    msg =
      case Map.get(state.started_spiders, spider_name) do
        nil ->
          {:error, :spider_not_running}

        %{crawl_id: crawl_id} ->
          {:ok, crawl_id}
      end

    {:reply, msg, state}
  end

  def handle_call(:running_spiders, _from, state) do
    {:reply, state.started_spiders, state}
  end

  def handle_call({:get_spider_info, name}, _from, state) do
    {:reply, get_spider_info_from_state(state, name), state}
  end

  def handle_call(:list_started_spiders, _from, state) do
    infos =
      for {name, stored} <- state.started_spiders do
        format_individual_spider_info(name, stored)
      end

    {:reply, infos, state}
  end

  def handle_call(:list_spider_templates, _from, state) do
    {:reply, state.known_spiders, state}
  end

  def handle_call(
        {:start_spider, spider_template, opts},
        _form,
        state
      ) do
    {msg, new_started_spiders} =
      case Map.get(state.started_spiders, opts[:name]) do
        nil ->
          # queue the async spider execution
          engine_pid = self()

          Task.start_link(fn ->
            result =
              Crawly.EngineSup.start_spider(
                spider_template,
                Map.to_list(opts)
              )

            send(engine_pid, {:start_spider_result, result, opts[:name]})
          end)

          {:ok,
           Map.put(state.started_spiders, opts[:name], %{
             pid: nil,
             status: :initializing,
             name: opts[:name],
             template: spider_template,
             crawl_id: opts[:crawl_id],
             workers: nil
           })}

        _ ->
          {{:error, :spider_already_started}, state.started_spiders}
      end

    {:reply, msg, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  def handle_call({:stop_spider, template, reason}, _form, state)
      when is_atom(template) do
    # spiders to stop

    to_stop =
      for {name, info} <- state.started_spiders,
          info.template == template do
        name
      end

    Logger.debug(
      "Stopping spiders: #{Enum.join(to_stop, ", ")}\nReason: #{inspect(reason)}"
    )

    engine_pid = self()

    for spider_name <- to_stop do
      Task.start_link(fn ->
        result = do_stop_spider(spider_name, reason, state.started_spiders)
        send(engine_pid, {:stop_spider_result, result, spider_name})
      end)
    end

    {:reply, :ok, state}
  end

  def handle_call({:stop_spider, spider_name, reason}, _form, state)
      when is_binary(spider_name) do
    Logger.debug("Stopping spider: #{spider_name}\nReason: #{inspect(reason)}")
    # fire off tasks to stop the spider
    engine_pid = self()

    Task.start_link(fn ->
      result = do_stop_spider(spider_name, reason, state.started_spiders)
      send(engine_pid, {:stop_spider_result, result, spider_name})
    end)

    {:reply, :ok, state}
  end

  def handle_cast(:refresh_spider_list, state) do
    updated = get_updated_known_spider_list(state.known_spiders)
    {:noreply, %Crawly.Engine{state | known_spiders: updated}}
  end

  # start the spider manager asyncronously
  def handle_info(
        {:start_spider_result, {:ok, pid}, name},
        %{
          started_spiders: started
        } = state
      ) do
    updated =
      case Map.get(started, name) do
        nil ->
          # not in started spiders, kill immediately
          Logger.debug(
            "Spider #{name} process was started, but was stopped before initialization complete. Killing process now."
          )

          Crawly.EngineSup.stop_spider(pid)
          Map.delete(started, name)

        current ->
          Map.put(started, name, %{
            current
            | status: :running,
              pid: pid
          })
      end

    {:noreply, %Crawly.Engine{state | started_spiders: updated}}
  end

  def handle_info({:start_spider_result, {:error, _} = err, spider_name}, state) do
    Logger.error("Could not start #{spider_name}. Reason: #{inspect(err)}")
    {:noreply, state}
  end

  def handle_info({:stop_spider_result, :ok, spider_name}, state) do
    Logger.debug("Successfully stopped spider: #{spider_name}.")
    updated = Map.delete(state.started_spiders, spider_name)
    {:noreply, %{state | started_spiders: updated}}
  end

  def handle_info({:stop_spider_result, {:error, reason}, spider_name}, state) do
    Logger.error(
      "Error occured when attempting to stop spider. \nSpider: #{spider_name}\nReason: #{
        inspect(reason)
      }"
    )

    {:noreply, state}
  end

  defp do_stop_spider(spider_name, reason, started_spiders) do
    case Crawly.Utils.get_settings(:on_spider_closed_callback, spider_name) do
      nil -> :ignore
      fun -> apply(fun, [reason])
    end

    case Map.get(started_spiders, spider_name) do
      nil ->
        {:error, :spider_not_running}

      %{pid: nil, status: :initializing} ->
        # currently initializing, will auto terminate immediately when initialization is complete
        # update the stop spider reason to the spider state
        :ok

      %{pid: pid} ->
        Crawly.EngineSup.stop_spider(pid)
        :ok
    end
  end

  defp get_spider_info_from_state(state, name) do
    case Map.get(state.started_spiders, name) do
      nil ->
        nil

      stored ->
        format_individual_spider_info(name, stored)
    end
  end

  defp format_individual_spider_info(name, stored) do
    worker_count =
      case Crawly.Manager.worker_pool_pid(name) do
        nil ->
          0

        pid ->
          pid
          |> DynamicSupervisor.count_children()
          |> Map.get(:active)
      end

    stored
    |> Map.merge(%{name: name, workers: worker_count})

    # |> Map.merge(manager_stats)
  end

  defp get_updated_known_spider_list(known \\ []) do
    new = Crawly.Utils.list_spiders()

    (known ++ new)
    |> Enum.dedup_by(& &1)
  end

  defp set_spider_log(spider_name, crawl_id) do
    log_dir = Crawly.Utils.get_settings(:log_dir, spider_name, "/tmp")
    Logger.add_backend({LoggerFileBackend, :debug})

    Logger.configure_backend({LoggerFileBackend, :debug},
      path: "/#{log_dir}/#{spider_name}/#{crawl_id}.log",
      level: :debug,
      metadata_filter: [crawl_id: crawl_id]
    )
  end
end
