defmodule CrawldisWeb.ApiSocket do
  use Phoenix.Socket
  require Logger
  channel("cluster", CrawldisWeb.ClusterChannel)

  def connect(params, socket, _connect_info) do
    Logger.debug(
      "[#{__MODULE__}] Attempt to connect received, #{inspect(params)}"
    )

    access_token = Map.get(params, "api_key")
    node_name = Map.get(params, "node_name")

    with {:ok, %_{resource_owner_id: user_id}} <-
           CrawldisPanel.Cluster.verify_token(access_token) do
      Logger.debug("[#{__MODULE__}] Attempt to connect was successful")
      user = CrawldisPanel.Accounts.get_user!(user_id)

      {:ok, assign(socket, user: user, node_name: node_name)}
    else
      _ -> :error
    end
  end

  def id(socket), do: "api_socket:#{socket.assigns.user.id}"
end
