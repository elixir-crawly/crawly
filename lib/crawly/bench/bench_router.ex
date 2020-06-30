defmodule Crawly.Bench.BenchRouter do
  require Logger
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  @num "num"

  get "/" do
    conn = fetch_query_params(conn, [])
    %{@num => num} = conn.params
    Logger.info("Crawly Bench Request number #{num}")
    {n, ""} = Integer.parse(num)
    send_resp(conn, 200, "#{n + 1}")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
