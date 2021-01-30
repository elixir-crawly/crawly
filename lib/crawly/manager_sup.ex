defmodule Crawly.ManagerSup do
  # A supervisor module used to spawn Crawler trees
  @moduledoc false
  use Supervisor

  def start_link([spider_template, options]) do
    Supervisor.start_link(__MODULE__, [spider_template, options])
  end

  @impl true
  def init([spider_template, options]) do
    spider_name = Keyword.get(options, :name)

    name = Crawly.EngineSup.via(spider_name)

    children = [
      # This supervisor is used to spawn Worker processes
      {DynamicSupervisor, strategy: :one_for_one, name: name},

      # Starts spider manager process
      {Crawly.Manager, [spider_template, options]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
