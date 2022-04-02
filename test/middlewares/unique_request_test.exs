defmodule Middlewares.UniqueRequestTest do
  use ExUnit.Case, async: false

  @valid %Crawly.Request{url: "https://www.some_url.com"}

  @valid_with_fragment %Crawly.Request{url: "https://www.some_url.com#frag1"}

  test "Filters out requests non-unique urls" do
    middlewares = [Crawly.Middlewares.UniqueRequest]
    req = @valid
    state = %{spider_name: :test_spider, crawl_id: "123"}

    assert {_req, state} = Crawly.Utils.pipe(middlewares, req, state)
    # run again, should drop the request
    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)

    req_with_fragment = @valid_with_fragment

    # should drop the request
    assert {false, _state} = Crawly.Utils.pipe(middlewares, req_with_fragment, state)
  end
end
