defmodule Middlewares.DomainFilterTest do
  use ExUnit.Case, async: false

  setup do
    :meck.new(:test_spider, [:non_strict])

    :meck.expect(:test_spider, :base_url, fn ->
      "https://www.erlang-solutions.com"
    end)

    on_exit(fn ->
      :meck.unload()
    end)
  end

  test "Filters out requests that do not contain a spider's base_url" do
    middlewares = [Crawly.Middlewares.DomainFilter]
    req = %Crawly.Request{url: "https://www.some_url.com"}
    state = %{spider_name: :test_spider}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end

  test "Does not filter out requests with correct urls" do
    middlewares = [Crawly.Middlewares.DomainFilter]

    req = %Crawly.Request{
      url: "https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html"
    }

    state = %{spider_name: :test_spider}

    {maybe_request, _state} = Crawly.Utils.pipe(middlewares, req, state)
    assert %Crawly.Request{} = maybe_request
  end

  test "Filters out 'share' urls" do
    middlewares = [Crawly.Middlewares.DomainFilter]

    req = %Crawly.Request{
      url:
        "https://twitter.com?share=https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html"
    }

    state = %{spider_name: :test_spider}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end
end
