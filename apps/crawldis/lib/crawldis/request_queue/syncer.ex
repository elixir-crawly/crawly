defmodule Crawldis.RequestQueue.Syncer do
  alias Crawldis.RequestQueue
  require Logger
  use GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_crdt_pid, do: GenServer.call(__MODULE__, :pid)
  @impl true
  def init(_) do
    Logger.info("Request queue syncer initializing")
    :net_kernel.monitor_nodes(true, node_type: :visible)
    set_neighbours()
    {:ok, %{}}
  end

  @impl true
  def handle_call(:pid, _src, state), do: {:reply, self_crdt_pid(), state}

  @impl true
  def handle_info({:nodeup, _node, _node_type}, state) do
    set_neighbours()
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, _node, _node_type}, state) do
    set_neighbours()
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp set_neighbours() do
    {results, _failed_nodes} =
      :rpc.multicall(nodes(), __MODULE__, :get_crdt_pid, [])

    DeltaCrdt.set_neighbours(self_crdt_pid(), results)
  end

  defp nodes(), do: Node.list([:visible])

  defp self_crdt_pid do
    %{crdt_pid: self_crdt_pid} = RequestQueue.get_state()
    Logger.info("CRDT PID is #{inspect(self_crdt_pid)}")
    self_crdt_pid
  end
end
