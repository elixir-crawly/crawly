defmodule Crawly.Bench.BenchRouter do
  require Logger
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn = fetch_query_params(conn, [])
    # Generating subset links from url
    max = Enum.random([0, 0, 0, 0, 0, 0, 5, 5, 5, 20])
    links = Enum.map(0..max, fn _ -> build_url(UUID.uuid1()) <> "|" end)

    send_resp(conn, 200, links)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  @spec build_url() :: String.t()
  def build_url do
    port = Application.get_env(:crawly, :benchmark_port, 8085)
    hostname = Application.get_env(:crawly, :hostname)

    "http://#{hostname}:#{port}/"
  end

  @spec build_url(String.t()) :: String.t()
  def build_url(item), do: build_url() <> "/?id=" <> item
end
