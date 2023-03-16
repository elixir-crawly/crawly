defmodule APITest do
  use ExUnit.Case
  use Plug.Test

  @opts Crawly.API.Router.init([])

  setup do
    on_exit(fn ->
      :get
      |> conn("/spiders/TestSpider/stop", "")
      |> Crawly.API.Router.call(@opts)
    end)
  end

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

  test "It's possible to get preview page" do
    conn =
      :get
      |> conn("/spiders/TestSpider/schedule", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Started!"

    conn =
      :get
      |> conn("/spiders/TestSpider/items", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
  end

  test "It's possible to get requests preview page" do
    conn =
      :get
      |> conn("/spiders/TestSpider/schedule", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Started!"

    conn =
      :get
      |> conn("/spiders/TestSpider/requests", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
  end
end
