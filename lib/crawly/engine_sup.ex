defmodule Crawly.EngineSup do
  # Engine supervisor responsible for spider subtrees
  @moduledoc false
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # returns the spider manager pid
  def start_spider(spider_template, options) do
    case Code.ensure_loaded?(spider_template) do
      true ->
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
end
