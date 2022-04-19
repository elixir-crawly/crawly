defmodule Crawly.Engine do
  @moduledoc """
  Crawly Engine - process responsible for starting and stopping spiders.

  Stores all currently running spiders.
  """
  require Logger

  use GenServer

  @type t :: %__MODULE__{
          started_spiders: started_spiders(),
          known_spiders: [Crawly.spider()]
        }

  @type started_spiders() :: %{optional(Crawly.spider()) => identifier()}

  @type spider_info() :: %{
          name: Crawly.spider(),
          status: :stopped | :started,
          pid: identifier() | nil
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
  @type crawl_id_opt :: {:crawl_id, binary()} | GenServer.option()
  @spec start_spider(Crawly.spider(), opts) :: result
        when opts: [crawl_id_opt],
             result:
               :ok
               | {:error, :spider_already_started}
               | {:error, :atom}
  def start_spider(spider_name, opts \\ [])

  def start_spider(spider_name, crawl_id) when is_binary(crawl_id) do
    Logger.warn(
      "Deprecation Warning: Setting the crawl_id as second positional argument is deprecated. Please use the :crawl_id option instead. Refer to docs for more info (https://hexdocs.pm/crawly/Crawly.Engine.html#start_spider/2) "
    )

    start_spider(spider_name, crawl_id: crawl_id)
  end

  def start_spider(spider_name, opts) when is_list(opts) do
    opts =
      Enum.into(opts, %{})
      |> Map.put_new_lazy(:crawl_id, &UUID.uuid1/0)

    # Filter all logs related to a given spider
    case {Crawly.Utils.get_settings(:log_to_file, spider_name),
          Crawly.Utils.ensure_loaded?(LoggerFileBackend)} do
      {true, true} ->
        configure_spider_logs(spider_name, opts[:crawl_id])

      {true, false} ->
        Logger.warn(
          ":logger_file_backend https://github.com/onkel-dirtus/logger_file_backend#loggerfilebackend must be installed as a peer dependency if log_to_file config is set to true"
        )

      _ ->
        false
    end

    GenServer.call(
      __MODULE__,
      {:start_spider, spider_name, opts[:crawl_id], Map.to_list(opts)}
    )
  end

  @spec get_manager(Crawly.spider()) :: pid() | {:error, :spider_not_found}
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

  @spec stop_spider(Crawly.spider(), reason) :: result
        when reason: :itemcount_limit | :itemcount_timeout | atom(),
             result:
               :ok | {:error, :spider_not_running} | {:error, :spider_not_found}
  def stop_spider(spider_name, reason \\ :ignore) do
    GenServer.call(__MODULE__, {:stop_spider, spider_name, reason})
  end

  @spec list_known_spiders() :: [spider_info()]
  def list_known_spiders() do
    GenServer.call(__MODULE__, :list_known_spiders)
  end

  @spec running_spiders() :: started_spiders()
  def running_spiders() do
    GenServer.call(__MODULE__, :running_spiders)
  end

  @spec get_spider_info(Crawly.spider()) :: spider_info() | nil
  def get_spider_info(spider_name) do
    GenServer.call(__MODULE__, {:get_spider, spider_name})
  end

  def refresh_spider_list() do
    GenServer.cast(__MODULE__, :refresh_spider_list)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec get_crawl_id(Crawly.spider()) ::
          {:error, :spider_not_running} | {:ok, binary()}
  def get_crawl_id(spider_name) do
    GenServer.call(__MODULE__, {:get_crawl_id, spider_name})
  end

  @spec init(any) :: {:ok, t()}
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

        {_pid, crawl_id} ->
          {:ok, crawl_id}
      end

    {:reply, msg, state}
  end

  def handle_call(:running_spiders, _from, state) do
    {:reply, state.started_spiders, state}
  end

  def handle_call(:list_known_spiders, _from, state) do
    return = Enum.map(state.known_spiders, &format_spider_info(&1, state))
    {:reply, return, state}
  end

  def handle_call(
        {:start_spider, spider_name, crawl_id, options},
        _form,
        state
      ) do
    result =
      case Map.get(state.started_spiders, spider_name) do
        nil ->
          Crawly.EngineSup.start_spider(spider_name, options)

        _ ->
          {:error, :spider_already_started}
      end

    {msg, new_started_spiders} =
      case result do
        {:ok, pid} ->
          {:ok, Map.put(state.started_spiders, spider_name, {pid, crawl_id})}

        {:error, _} = err ->
          {err, state.started_spiders}
      end

    {:reply, msg, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  def handle_call({:stop_spider, spider_name, reason}, _form, state) do
    {msg, new_started_spiders} =
      case Map.pop(state.started_spiders, spider_name) do
        {nil, _} ->
          {{:error, :spider_not_running}, state.started_spiders}

        {{pid, crawl_id}, new_started_spiders} ->
          case Crawly.Utils.get_settings(
                 :on_spider_closed_callback,
                 spider_name
               ) do
            nil -> :ignore
            fun -> apply(fun, [spider_name, crawl_id, reason])
          end

          Crawly.EngineSup.stop_spider(pid)

          {:ok, new_started_spiders}
      end

    {:reply, msg, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  def handle_call({:get_spider, spider_name}, _from, state) do
    return =
      if Enum.member?(state.known_spiders, spider_name) do
        format_spider_info(spider_name, state)
      end

    {:reply, return, state}
  end

  def handle_cast(:refresh_spider_list, state) do
    updated = get_updated_known_spider_list(state.known_spiders)
    {:noreply, %Crawly.Engine{state | known_spiders: updated}}
  end

  # this function generates a spider_info map for each spider known
  defp format_spider_info(spider_name, state) do
    pid = Map.get(state.started_spiders, spider_name)

    %{
      name: spider_name,
      status: if(is_nil(pid), do: :stopped, else: :started),
      pid: pid
    }
  end

  defp get_updated_known_spider_list(known \\ []) do
    new = Crawly.Utils.list_spiders()

    (known ++ new)
    |> Enum.dedup_by(& &1)
  end

  defp configure_spider_logs(spider_name, crawl_id) do
    log_dir =
      Crawly.Utils.get_settings(
        :log_dir,
        spider_name,
        System.tmp_dir()
      )

    current_unix_timestamp = :os.system_time(:second)

    Logger.add_backend({LoggerFileBackend, :debug})

    log_file_path =
      Path.join([
        log_dir,
        inspect(spider_name),
        # underscore separates the timestamp and the crawl_id
        inspect(current_unix_timestamp) <> "_" <> crawl_id
      ]) <> ".log"

    Logger.configure_backend({LoggerFileBackend, :debug},
      path: log_file_path,
      level: :debug,
      metadata_filter: [crawl_id: crawl_id]
    )

    Logger.debug("Writing logs to #{log_file_path}")
  end
end
