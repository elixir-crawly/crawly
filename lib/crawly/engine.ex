defmodule Crawly.Engine do
  @moduledoc """

  Engine module
  """
  require Logger

  use GenServer

  defstruct started_spiders: %{}

  def start_spider(spider_name) do
    GenServer.call(__MODULE__, {:start_spider, spider_name})
  end

  def stop_spider(spider_name) do
    GenServer.call(__MODULE__, {:stop_spider, spider_name})
  end

  def running_spiders() do
    GenServer.call(__MODULE__, :running_spiders)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %Crawly.Engine{}}
  end

  def handle_call(:running_spiders, _from, state) do
    running_spiders = state.started_spiders
    msg =
      case Enum.count(running_spiders) do
        0 ->
          "No spiders are currently running"
        _ ->
          "Following spiders are running currently: #{inspect(running_spiders)}"
      end
    {:reply, msg, state}
  end

  def handle_call({:start_spider, spider_name}, _form, state) do
    {msg, pid} =
      case Map.get(state.started_spiders, spider_name) do
        nil ->
          Crawly.EngineSup.start_spider(spider_name)

        pid ->
          {{:error, :spider_already_started}, pid}
      end
    new_started_spiders = Map.put(state.started_spiders, spider_name, pid)
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
