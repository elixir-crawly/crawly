defmodule Crawly.Bench.BenchRouter do
  require Logger
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn = fetch_query_params(conn, [])
    %{"str" => str} = conn.params
    url = build_url(str)

    num_of_workers =
      Application.get_env(:crawly, :concurrent_requests_per_domain)

    # Generating subset links from url
    links = Enum.map(1..num_of_workers, &(url <> "#{&1}|"))

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
  def build_url(item), do: build_url() <> "/?str=" <> item
end
