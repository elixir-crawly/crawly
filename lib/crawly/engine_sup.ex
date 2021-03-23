defmodule Crawly.EngineSup do
  # Engine supervisor responsible for spider subtrees
  @moduledoc false

  def start_spider(spider_name, options) do
    result =
      case Code.ensure_loaded?(spider_name) do
        true ->
          # Given spider module exists in the namespace, we can proceed
          DynamicSupervisor.start_child(
            __MODULE__,
            {Crawly.ManagerSup, [spider_name, options]}
          )

        false ->
          {:error, "Spider: #{inspect(spider_name)} was not defined"}
      end

    result
  end

  def stop_spider(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
