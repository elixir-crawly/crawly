defmodule Crawly.DataStorage.Worker do
  require Logger

  use GenServer

  def start_link(spider_name: spider_name) do
    GenServer.start_link(__MODULE__, spider_name: spider_name)
  end

  def store(pid, item) do
    GenServer.cast(pid, {:store, item})
    Logger.info("Storing item: #{inspect(pid)}/#{inspect(item)}")
  end

  def init(spider_name: spider_name) do
    base_path = Application.get_env(:crawly, :base_store_path, "/tmp/")

    {:ok, fd} =
      File.open("#{base_path}#{inspect(spider_name)}.json", [
        :binary,
        :write,
        :delayed_write
      ])

    {:ok, %{fd: fd}}
  end

  def handle_cast({:store, item}, state) do
    pipelines = Application.get_env(:crawly, :pipelines, [])

    # Update the state of the data storage worker after running
    # pipelines
    state =
      case pipeline_runner(pipelines, item, state) do
        {false, new_state} ->
          new_state

        {new_item, new_state} ->
          IO.write(state.fd, Poison.encode!(new_item))
          new_state
      end

    {:noreply, state}
  end

  defp pipeline_runner([], item, state), do: {item, state}

  defp pipeline_runner(_, false, state), do: {false, state}

  defp pipeline_runner([pipeline | pipelines], item, state) do
    {new_item, new_state} = pipeline.run(item, state)
    pipeline_runner(pipelines, new_item, new_state)
  end
end
