defmodule Crawly.Engine do
  @moduledoc """
  Crawly Engine - process responsible for starting and stopping spiders.

  Stores all currently running spiders.
  """
  require Logger

  use GenServer

  @type t :: %__MODULE__{started_spiders: started_spiders()}
  @type started_spiders() :: %{optional(module()) => identifier()}
  @type list_spiders() :: [
          %{name: module(), state: :stopped | :started, pid: identifier()}
        ]

  defstruct started_spiders: %{}

  @spec start_spider(module()) ::
          :ok
          | {:error, :spider_already_started}
          | {:error, :atom}
  def start_spider(spider_name) do
    GenServer.call(__MODULE__, {:start_spider, spider_name})
  end

  @spec start_all_spiders() :: :ok
  def start_all_spiders() do
    GenServer.call(__MODULE__, {:start_all_spiders, nil})
  end

  @spec get_manager(module()) :: pid() | {:error, :spider_not_found}
  def get_manager(spider_name) do
    case Map.fetch(running_spiders(), spider_name) do
      :error ->
        {:error, :spider_not_found}

      {:ok, pid_sup} ->
        Supervisor.which_children(pid_sup)
        |> Enum.find(&({Crawly.Manager, _, :worker, [Crawly.Manager]} = &1))
        |> case do
          nil -> {:error, :spider_not_found}
          {_, pid, :worker, _} -> pid
        end
    end
  end

  @spec stop_spider(module(), reason) :: result
        when reason: :itemcount_limit | :itemcount_timeout | atom(),
             result: :ok | {:error, :spider_not_running}
  def stop_spider(spider_name, reason \\ :ignore) do
    case Crawly.Utils.get_settings(:on_spider_closed_callback, spider_name) do
      nil -> :ignore
      fun -> apply(fun, [reason])
    end

    GenServer.call(__MODULE__, {:stop_spider, spider_name})
  end

  @spec list_spiders() :: list_spiders()
  def list_spiders() do
    GenServer.call(__MODULE__, :list_spiders)
  end

  @spec running_spiders() :: started_spiders()
  def running_spiders() do
    GenServer.call(__MODULE__, :running_spiders)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec init(any) :: {:ok, __MODULE__.t()}
  def init(_args) do
    {:ok, %Crawly.Engine{}}
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

  def handle_call(:running_spiders, _from, state) do
    {:reply, state.started_spiders, state}
  end

  def handle_call(:list_spiders, _from, state) do
    {:reply, list_all_spider_status(state.started_spiders), state}
  end

  def handle_call({:start_spider, spider_name}, _form, state) do
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
          {:ok, Map.put(state.started_spiders, spider_name, pid)}

        {:error, _} = err ->
          {err, state.started_spiders}
      end

    {:reply, msg, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  def handle_call({:start_all_spiders, nil}, _form, state) do
    stopped =
      list_all_spider_status(state.started_spiders)
      |> Enum.filter(fn s -> s.state == :stopped end)

    # start all stopped spiders
    new_started_spiders =
      Enum.reduce(stopped, state.started_spiders, fn spider_status, acc ->
        Crawly.EngineSup.start_spider(spider_status.name)
        |> case do
          {:ok, pid} ->
            Map.put(acc, spider_status.name, pid)

          _ ->
            acc
        end
      end)

    # returns ok regardless of whether errors encountered
    {:reply, :ok, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  def handle_call({:stop_spider, spider_name}, _form, state) do
    {msg, new_started_spiders} =
      case Map.pop(state.started_spiders, spider_name) do
        {nil, _} ->
          {{:error, :spider_not_running}, state.started_spiders}

        {pid, new_started_spiders} ->
          Crawly.EngineSup.stop_spider(pid)

          {:ok, new_started_spiders}
      end

    {:reply, msg, %Crawly.Engine{state | started_spiders: new_started_spiders}}
  end

  defp list_all_spider_status(started_spiders) do
    Crawly.Utils.list_spiders()
    |> Enum.map(fn name ->
      %{
        name: name,
        state:
          case Map.has_key?(started_spiders, name) do
            true -> :started
            false -> :stopped
          end,
        pid: Map.get(started_spiders, name)
      }
    end)
  end
end
