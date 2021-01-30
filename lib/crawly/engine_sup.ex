defmodule Crawly.EngineSup do
  # Engine supervisor responsible for spider subtrees
  @moduledoc false
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # returns the spider manager pid
  def start_spider(spider_template, options) do
    case Code.ensure_loaded?(spider_template) do
      true ->
        # Given spider module exists in the namespace, we can proceed

        case DynamicSupervisor.start_child(
               __MODULE__,
               {Registry, [keys: :unique, name: Crawly.Engine.Registry]}
             ) do
          {:error, {:already_started, _}} -> :ok
          {:ok, _pid} -> :ok
        end

        DynamicSupervisor.start_child(
          __MODULE__,
          {Crawly.ManagerSup, [spider_template, options]}
        )

      false ->
        {:error,
         "Spider template module: #{inspect(spider_template)} was not defined"}
    end
  end

  def stop_spider(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def via(spider_name),
    do: {:via, Registry, {Crawly.Engine.Registry, spider_name}}
end
