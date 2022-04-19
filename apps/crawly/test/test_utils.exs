defmodule TestUtils do
  def stop_process(pid) do
    :erlang.exit(pid, :shutdown)
    wait_pid(pid)
    :ok
  end

  def wait_pid(pid, timeout \\ 5_000) do
    :erlang.monitor(:process, pid)

    result =
      receive do
        {:DOWN, _, _, ^pid, reason} -> {:ok, reason}
      after
        timeout -> timeout
      end

    result
  end
end
