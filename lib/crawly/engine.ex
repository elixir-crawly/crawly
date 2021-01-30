defmodule Crawly.Engine do
  @moduledoc """
  Crawly Engine - process responsible for starting and stopping spiders.

  Stores all currently running spiders.
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
          status: :initializing | :running | :stopping,
          stop_reason: nil | atom()
        }

  defstruct(started_spiders: %{}, known_spiders: [])

  @doc """
  Starts a spider. All options passed in the second argument will be passed along to the spider's `init/1` callback.

  ### Reserved Options
  - `:crawl_id` (binary). Optional, automatically generated if not set.
  - `:closespider_itemcount` (integer | disabled). Optional, overrides the close
    spider item count on startup.
  - `:closespider_timeout` (integer | disabled). Optional, overrides the close
                            spider timeout on startup.
  - `:concurrent_requests_per_domain` (integer). Optional, overrides the number of
     workers for a given spider

  ### Backward compatibility
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
      when is_list(opts)
      when is_atom(spider_template) do
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

  @spec get_manager(module()) ::
          pid() | {:error, :spider_not_found}
  def get_manager(spider_name) do
    case Map.fetch(running_spiders(), spider_name) do
      :error ->
        {:error, :spider_not_found}

      {:ok, {pid_sup, _job_tag}} ->
        Supervisor.which_children(pid_sup)
        |> Enum.find(&({Crawly.Manager, _, :worker, [Crawly.Manager]} = &1))
        |> case do
          nil ->
            {:error, :spider_not_found}

          {_, pid, :worker, _} ->
            pid
        end
    end
  end

  @spec stop_spider(module() | String.t(), reason) :: result
        when reason: :itemcount_limit | :itemcount_timeout | atom(),
             result:
               :ok | {:error, :spider_not_running} | {:error, :spider_not_found}

  def stop_spider(spider_name, reason \\ :ignore) do
    GenServer.call(__MODULE__, {:stop_spider, spider_name, reason})
  end

  @spec list_started_spiders() :: [spider_info()]
  def list_started_spiders() do
    GenServer.call(__MODULE__, :list_started_spiders)
  end

  @spec list_spider_templates() :: [module()]
  def list_spider_templates() do
    GenServer.call(__MODULE__, :list_spider_templates)
  end

  @spec running_spiders() :: started_spiders()
  def running_spiders() do
    GenServer.call(__MODULE__, :running_spiders)
  end

  @spec get_spider_info(String.t() | module()) :: spider_info()
  def get_spider_info(name) when is_binary(name) do
    GenServer.call(__MODULE__, {:get_spider_info, name})
  end

  def get_spider_info(name) when is_atom(name),
    do: name |> Atom.to_string() |> get_spider_info()

  def refresh_spider_list() do
    GenServer.cast(__MODULE__, :refresh_spider_list)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec get_crawl_id(String.t() | module()) ::
          {:error, :spider_not_running} | {:ok, binary()}
  def get_crawl_id(spider_name) when is_binary(spider_name) do
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
    pid =
      case Map.get(state.started_spiders, spider_name) do
        nil ->
          {:error, :spider_not_found}

        pid ->
          pid
      end

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
          engine_pid = self()
          # fire off async task to start the server
          {:ok, task_pid} =
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
             task_pid: task_pid,
             status: :initializing,
             name: opts[:name],
             template: spider_template,
             crawl_id: opts[:crawl_id]
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

    Logger.debug("Stopping spiders: #{Enum.join(to_stop, ", ")}")
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
    Logger.debug("Stopping spider: #{spider_name}")
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
              pid: pid,
              task_pid: nil
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

      %{pid: nil, task_pid: _task_pid} ->
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
    Map.merge(stored, %{name: name})
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
