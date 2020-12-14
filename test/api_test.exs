defmodule APITest do
  use ExUnit.Case
  use Plug.Test

  @opts Crawly.API.Router.init([])

  test "returns welcome" do
    conn =
      :get
      |> conn("/spiders", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "No spiders are currently running"
  end

  test "scheduling spiders" do
    conn =
      :get
      |> conn("/spiders/TestSpider/schedule", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Started!"

    Process.sleep(400)

    conn =
      :get
      |> conn("/spiders/TestSpider/stop", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Stopped!"
  end
end
