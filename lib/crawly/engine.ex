defmodule Crawly.Engine do
  @moduledoc """
  Crawly Engine - process responsible for starting and stopping spiders.

  Stores all currently running spiders.
  """
  require Logger

  use GenServer

  @type t :: %__MODULE__{started_spiders: started_spiders()}
  @type started_spiders() :: %{optional(module()) => identifier()}

  defstruct started_spiders: %{}

  @spec start_spider(module()) ::
          :ok
          | {:error, :spider_already_started}
          | {:error, :atom}
  def start_spider(spider_name) do
    GenServer.call(__MODULE__, {:start_spider, spider_name})
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

  def handle_call(:running_spiders, _from, state) do
    {:reply, state.started_spiders, state}
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
end
