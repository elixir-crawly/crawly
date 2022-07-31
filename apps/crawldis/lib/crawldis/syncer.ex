defmodule Crawldis.Syncer do
  @moduledoc """
  Syncs a crdt across nodes (not across processes).

  Required init kw args:
  - `:name` - locally identifiable process name, used for rpc calls
  - `:get_pid` - anonymous function to retrieve the pid of the crdt
  """
  require Logger
  use GenServer
  use TypedStruct
  typedstruct enforce: true do
  end

  def start_link(opts) do
    opts = Enum.into(opts, %{
      name: nil,
      node: Node.self(),
      get_pid: fn ->
        raise "get_pid for retrieving the crdt pid for Syncer is not set!"
      end
    })
    name = get_global_name(node, opts.name)
    GenServer.start_link(__MODULE__, opts, [name: name])
  end

  @impl true
  def init(opts) do
    Logger.debug("Syncer initializing")
    :net_kernel.monitor_nodes(true, node_type: :visible)
    state = opts
    set_neighbours(state)
    {:ok, state}
  end

  @impl true
  def handle_call(:pid, _src, state), do: {:reply, state.get_pid.(), state}

  @impl true
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_neighbours(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, _node, _node_type}, state) do
    set_neighbours(state)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp set_neighbours(%{name: name}= state) do
    pids = for node <- nodes(), pid  = :global.whereis_name({node, name}), is_pid(pid) do
      pid
    end

    DeltaCrdt.set_neighbours(state.get_pid.(), pids)
  end

  defp nodes(), do: Node.list([:visible])

  defp get_global_name(node, name), do: {:global, {node, name}}
end
