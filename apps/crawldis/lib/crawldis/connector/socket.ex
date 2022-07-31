defmodule Crawldis.Connector.Socket do
  require Logger
  alias Crawldis.Utils

  def child_spec(_) do
    config = Utils.get_panel_config!()
    node = Utils.self()
    url = "ws://#{config.endpoint}/api_socket/websocket?api_key=#{config.api_key}&node_name=#{node}"
    socket_opts = [url:  url]
    %{
      id: __MODULE__,
      start: {PhoenixClient.Socket, :start_link, [socket_opts, [name: __MODULE__]]}
    }
  end
end
