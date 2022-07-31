defmodule Crawldis.Connector.Worker do
  @moduledoc """
  Connects to the control panel server
  """
  require Logger
  alias Crawldis.Connector.{Socket}
  use GenServer
  alias PhoenixClient.{Channel, Message}
  alias Crawldis.Jobber
  def start_link(_state) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_opts) do
    {:ok, %{ channel: nil, retry_times: 0}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    case Channel.join(Socket, "cluster") do
      {:ok, response, channel} ->
        Logger.debug("Connected to server. response: #{inspect(response)}")
        {:noreply, Map.put(state, :channel, channel)}
      {:error, _} =err ->
        Logger.debug("Error when attempting to join: #{inspect err}. Reattempting in 1s...")
        if state.retry_times > 3 do
          Crawldis.Connector.reconnect()
        end
        state = %{state | retry_times: state.retry_times + 1}
        :timer.sleep(1000)
        {:noreply, state, {:continue, :connect}}
    end
  end
  def handle_info(%Message{event: "list_crawls", payload: _payload}, %{channel: channel}= state) do
    Logger.debug("connector/worker | Listing crawl jobs")
    list_and_broadcast(channel)

    {:noreply, state}
  end
  def handle_info(%Message{event: "create_crawl", payload: payload}, %{channel: channel} = state) do
    Logger.debug("connector/worker | Creating crawl job, payload: #{inspect payload}")
    {:ok, job} = Jobber.start_job(payload)
    Channel.push_async(channel, "reply:create_crawl", %{"job"=> job})
    list_and_broadcast(channel)

    {:noreply, state}
  end

  def handle_info(%Message{event: "stop_crawl", payload: %{"id"=> id}}, %{channel: channel} = state) do
    Logger.debug("connector/worker | Stopping crawl job, id: #{inspect id}")
    :ok = Jobber.stop_job(id)
    list_and_broadcast(channel)
    {:noreply, state}
  end
  def handle_info(%{event: "presence_diff"}, state), do: {:noreply, state}

  def handle_info(msg, state) do
    Logger.warn("Unknown message from panel received. msg: #{inspect msg}")
    {:noreply, state}
  end

  defp list_and_broadcast(channel) do
    jobs = Jobber.list_jobs()
    Channel.push_async(channel, "reply:list_crawls", %{"jobs"=> jobs})
  end
end
