defmodule Middlewares.SameDomainFilterTest do
  use ExUnit.Case, async: false

  @base_url "https://www.erlang-solutions.com"

  setup do
    :meck.new(:test_spider, [:non_strict])

    on_exit(fn ->
      :meck.unload()
    end)
  end

  test "Initial request always passes" do
    middlewares = [Crawly.Middlewares.SameDomainFilter]

    req = %Crawly.Request{
      url: @base_url,
      prev_response: nil
    }

    state = %{spider_name: :test_spider, crawl_id: "id"}

    {maybe_request, _state} = Crawly.Utils.pipe(middlewares, req, state)
    assert %Crawly.Request{} = maybe_request
  end

  test "Filters out requests that do not contain a spider's start_url" do
    middlewares = [Crawly.Middlewares.SameDomainFilter]

    req = %Crawly.Request{
      url: "https://www.some_url.com",
      prev_response: %HTTPoison.Response{request_url: @base_url}
    }

    state = %{spider_name: :test_spider, crawl_id: "id"}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end

  test "Does not filter out requests with correct urls" do
    middlewares = [Crawly.Middlewares.SameDomainFilter]

    req = %Crawly.Request{
      url:
        "https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html",
      prev_response: %HTTPoison.Response{request_url: @base_url}
    }

    state = %{spider_name: :test_spider, crawl_id: "id"}

    {maybe_request, _state} = Crawly.Utils.pipe(middlewares, req, state)
    assert %Crawly.Request{} = maybe_request
  end

  test "Filters out 'share' urls" do
    middlewares = [Crawly.Middlewares.SameDomainFilter]

    req = %Crawly.Request{
      url:
        "https://twitter.com?share=https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html",
      prev_response: %HTTPoison.Response{request_url: @base_url}
    }

    state = %{spider_name: :test_spider, crawl_id: "id"}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end

  test "Non absolute url should not crash the middleware" do
    middlewares = [Crawly.Middlewares.SameDomainFilter]

    req = %Crawly.Request{
      url: "/blog",
      prev_response: %HTTPoison.Response{request_url: @base_url}
    }

    state = %{spider_name: :test_spider, crawl_id: "id"}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end
end
