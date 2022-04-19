defmodule Middlewares.RobotsTxtTest do
  use ExUnit.Case, async: false

  @valid %Crawly.Request{url: "https://www.some_url.com/my_site"}
  setup do
    on_exit(fn ->
      :meck.unload()
    end)
  end

  test "Filters out requests that are not permitted by robots.txt" do
    :meck.expect(Gollum, :crawlable?, fn _ua, _url -> :uncrawlable end)

    middlewares = [Crawly.Middlewares.RobotsTxt]
    req = @valid
    state = %{spider_name: :test_spider, crawl_id: "123"}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end
end
