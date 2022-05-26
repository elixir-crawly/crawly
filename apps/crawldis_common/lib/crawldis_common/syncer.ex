defmodule CrawldisCommon.Syncer do
  @moduledoc """
  Syncs a crdt across nodes (not across processes).

  Required init kw args:
  - `:name` - locally identifiable process name, used for rpc calls
  - `:get_pid` - anonymous function to retrieve the pid of the crdt
  """
  require Logger
  use GenServer

  @type t :: %__MODULE__{
    get_pid: fun(),
    name: module()
  }
  defstruct get_pid: nil, name: nil

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts[:get_pid], opts[:name]], [name: opts[:name]])
  end

  @impl true
  def init([get_pid, name]) do
    Logger.debug("Syncer initializing")
    if is_nil get_pid do
      raise "Syncer must be initialized with a get_pid function"
    end
    :net_kernel.monitor_nodes(true, node_type: :visible)
    state = %__MODULE__{get_pid: get_pid, name: name}
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

  defp set_neighbours(%__MODULE__{}= state) do
    {results, _failed_nodes} =
      :rpc.multicall(nodes(), GenServer, :call, [state.name, :pid])

    DeltaCrdt.set_neighbours(state.get_pid.(), results)
  end

  defp nodes(), do: Node.list([:visible])
end
