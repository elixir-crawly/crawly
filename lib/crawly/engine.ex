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
  @type started_spiders() :: %{optional(module()) => identifier()}
  @type list_spiders() :: [
          %{name: module(), state: :stopped | :started, pid: identifier()}
        ]

  @type spider_info() :: %{
          name: module(),
          status: :stopped | :started,
          pid: identifier() | nil
        }

  defstruct(started_spiders: %{}, known_spiders: [])

  @spec start_spider(module(), binary()) ::
          :ok
          | {:error, :spider_already_started}
          | {:error, :atom}
  def start_spider(spider_name, crawl_id \\ UUID.uuid1()) do
    GenServer.call(__MODULE__, {:start_spider, spider_name, crawl_id})
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

  @spec stop_spider(module(), reason) :: result
        when reason: :itemcount_limit | :itemcount_timeout | atom(),
             result:
               :ok | {:error, :spider_not_running} | {:error, :spider_not_found}
  def stop_spider(spider_name, reason \\ :ignore) do
    case Crawly.Utils.get_settings(:on_spider_closed_callback, spider_name) do
      nil -> :ignore
      fun -> apply(fun, [reason])
    end

    GenServer.call(__MODULE__, {:stop_spider, spider_name})
  end

  @spec stop_all_spiders() :: :ok
  @doc "Stops all spiders, regardless of their current state. Runs :on_spider_closed_callback if available"
  def stop_all_spiders() do
    Crawly.Utils.list_spiders()
    |> Enum.each(fn name ->
      case Crawly.Utils.get_settings(:on_spider_closed_callback, name) do
        nil -> :ignore
        fun -> apply(fun, [:stop_all])
      end

      GenServer.call(__MODULE__, {:stop_spider, name})
    end)
  end

  @spec list_known_spiders() :: [spider_info()]
  def list_known_spiders() do
    GenServer.call(__MODULE__, :list_known_spiders)
  end

  @spec running_spiders() :: started_spiders()
  def running_spiders() do
    GenServer.call(__MODULE__, :running_spiders)
  end

  @spec get_spider_info(module()) :: spider_info()
  def get_spider_info(name) do
    GenServer.call(__MODULE__, {:get_spider, name})
  end

  def refresh_spider_list() do
    GenServer.cast(__MODULE__, :refresh_spider_list)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec get_crawl_id(atom()) :: {:error, :spider_not_running} | {:ok, binary()}
  def get_crawl_id(spider_name) do
    GenServer.call(__MODULE__, {:get_crawl_id, spider_name})
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

        {_pid, crawl_id} ->
          {:ok, crawl_id}
      end

    {:reply, msg, state}
  end

  def handle_call(:running_spiders, _from, state) do
    {:reply, state.started_spiders, state}
  end

  def handle_call(:list_known_spiders, _from, state) do
    {:reply, format_spider_info(state), state}
  end

  def handle_call({:start_spider, spider_name, crawl_id}, _form, state) do
    result =
      case Map.get(state.started_spiders, spider_name) do
        nil ->
          Crawly.EngineSup.start_spider(spider_name)

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

  def handle_call({:stop_spider, spider_name}, _form, state) do
    {msg, new_started_spiders} =
      case Map.pop(state.started_spiders, spider_name) do
        {nil, _} ->
          {{:error, :spider_not_running}, state.started_spiders}

        {{pid, _crawl_id}, new_started_spiders} ->
          Crawly.EngineSup.stop_spider(pid)

          {:ok, new_started_spiders}
      end

    {:reply, msg, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  def handle_cast(:refresh_spider_list, state) do
    updated = get_updated_known_spider_list(state.known_spiders)
    {:noreply, %Crawly.Engine{state | known_spiders: updated}}
  end

  # this function generates a spider_info map for each spider known
  defp format_spider_info(state) do
    Enum.map(state.known_spiders, fn s ->
      pid = Map.get(state.started_spiders, s)

      %{
        name: s,
        status: if(is_nil(pid), do: :stopped, else: :started),
        pid: pid
      }
    end)
  end

  defp get_updated_known_spider_list(known \\ []) do
    new = Crawly.Utils.list_spiders()

    (known ++ new)
    |> Enum.dedup_by(& &1)
  end
end
