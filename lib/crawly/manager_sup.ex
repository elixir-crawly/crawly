defmodule Crawly.ManagerSup do
  # A supervisor module used to spawn Crawler trees
  @moduledoc false
  use Supervisor

  def start_link(spider_name) do
    Supervisor.start_link(__MODULE__, spider_name)
  end

  @impl true
  def init(spider_name) do
    children = [
      # This supervisor is used to spawn Worker processes
      {DynamicSupervisor, strategy: :one_for_one, name: spider_name},

      # Starts spider manager process
      {Crawly.Manager, spider_name}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
