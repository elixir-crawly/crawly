defmodule CrawldisWeb.ClusterChannel do
  use CrawldisWeb, :channel
  require Logger
  alias CrawldisWeb.Presence

  def join("cluster", _payload, socket) do
    Logger.debug(
      "New node connected to cluster. node: #{socket.assigns.node_name}, user: #{socket.assigns.user.name}"
    )

    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.node_name, %{
        online_at: DateTime.utc_now() |> DateTime.to_iso8601()
      })

    {:noreply, socket}
  end

  def handle_in(event, msg, socket) do
    CrawldisWeb.Endpoint.broadcast("cluster:panel", event, msg)
    {:noreply, socket}
  end
end
