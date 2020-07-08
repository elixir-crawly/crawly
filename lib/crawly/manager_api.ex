defmodule Crawly.ManagerAPI do
  @moduledoc """
  TODO
  """

  alias Crawly.Engine

  @spec add_workers(module(), non_neg_integer()) ::
          :ok | {:error, :spider_non_exist}
  def add_workers(spider_name, num_of_workers) do
    case Engine.get_manager(spider_name) do
      {:error, reason} ->
        {:error, reason}

      pid ->
        GenServer.cast(pid, {:add_workers, num_of_workers})
    end
  end
end
