defmodule Crawly.ManagerSup do
  # A supervisor module used to spawn Crawler trees
  @moduledoc false
  use Supervisor

  def start_link([spider_name, options]) do
    Supervisor.start_link(__MODULE__, [spider_name, options])
  end

  @impl true
  def init([spider_name, options]) do
    children = [
      # This supervisor is used to spawn Worker processes
      {DynamicSupervisor, strategy: :one_for_one, name: spider_name},

      # Starts spider manager process
      {Crawly.Manager, [spider_name, options]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
