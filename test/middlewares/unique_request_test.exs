defmodule Middlewares.UniqueRequestTest do
  use ExUnit.Case, async: false

  @valid %Crawly.Request{url: "https://www.some_url.com"}
  @valid_slash %Crawly.Request{url: "https://www.some_url.com/"}

  test "Filters out requests non-unique urls" do
    middlewares = [Crawly.Middlewares.UniqueRequest]
    req = @valid
    state = %{spider_name: :test_spider, crawl_id: "123"}

    assert {_req, state} = Crawly.Utils.pipe(middlewares, req, state)
    # run again, should drop the request
    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end

  test "Filters out requests non-unique urls using hash" do
    middlewares = [{Crawly.Middlewares.UniqueRequest, hash: :sha256}]
    req = @valid
    state = %{spider_name: :test_spider, crawl_id: "123"}

    assert {_req, state} = Crawly.Utils.pipe(middlewares, req, state)
    # run again, should drop the request
    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end

  test "Ignores trailing slash" do
    middlewares = [Crawly.Middlewares.UniqueRequest]
    state = %{spider_name: :test_spider, crawl_id: "123"}

    assert {_req, state} = Crawly.Utils.pipe(middlewares, @valid, state)
    # run again, should drop the request
    assert {false, _state} = Crawly.Utils.pipe(middlewares, @valid_slash, state)
  end

  test "Uses the normalise_url function if given" do
    middlewares = [
      {Crawly.Middlewares.UniqueRequest, normalise_url: fn url -> url end}
    ]

    state = %{spider_name: :test_spider, crawl_id: "123"}

    assert {%Crawly.Request{}, state} =
             Crawly.Utils.pipe(middlewares, @valid, state)

    # run again, should not drop the request, because normalise_url overrides default
    assert {%Crawly.Request{}, _state} =
             Crawly.Utils.pipe(middlewares, @valid_slash, state)
  end
end
