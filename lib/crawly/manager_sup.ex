defmodule Crawly.ManagerSup do
  use Supervisor

  def start_link(spider_name) do
    Supervisor.start_link(__MODULE__, spider_name)
  end

  @impl true
  def init(spider_name) do

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: spider_name},
      {Crawly.Manager, spider_name}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
