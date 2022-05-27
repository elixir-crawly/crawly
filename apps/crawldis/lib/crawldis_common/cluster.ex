defmodule Crawldis.Cluster do
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
      {Cluster.Supervisor, [topologies, []]},
      {Horde.Registry,
       [name: __MODULE__.RequestorRegistry, keys: :unique, members: :auto]},
      {Horde.Registry,
       [name: __MODULE__.ProcessorRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor,
       [
         name: __MODULE__.DynamicSupervisor,
         strategy: :one_for_one,
         members: :auto
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def list_requestors do
    for child <-
          Horde.DynamicSupervisor.which_children(__MODULE__.DynamicSupervisor),
        {_, pid, _, [Crawldis.Requestor]} = child,
        keys = Horde.Registry.keys(__MODULE__.RequestorRegistry, pid),
        key <- List.flatten(keys) do
      key
    end
  end

  def start_requestor do
    id = UUID.uuid4()

    Horde.DynamicSupervisor.start_child(__MODULE__.DynamicSupervisor, %{
      id: id,
      start: {Crawldis.Requestor, :start_link, [id]},
      restart: :transient
    })

    {:ok, id}
  end

  def stop_requestor(id) when is_binary(id),
    do: Crawldis.Requestor.stop(id)
end
