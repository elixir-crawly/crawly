defmodule CrawldisCommon.ClusterSup do
  @moduledoc """
  Common Cluster supervisor for connecting nodes using gossip strategy
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, [])
  end

  @impl true
  def init(_init_arg) do
    topologies = [
      default: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, []]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
