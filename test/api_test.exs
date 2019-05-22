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

    conn =
      :get
      |> conn("/spiders/TestSpider/scheduled-requests", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "{:stored_requests, 1}"
    Process.sleep(1_000)
    conn =
      :get
      |> conn("/spiders/TestSpider/scraped-items", "")
      |> Crawly.API.Router.call(@opts)


    assert conn.resp_body == "{:stored_items, 1}"

    conn =
      :get
      |> conn("/spiders/TestSpider/stop", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Stopped!"
  end
end
