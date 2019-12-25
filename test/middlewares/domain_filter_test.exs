defmodule Middlewares.DomainFilterTest do
  use ExUnit.Case, async: false

  @valid %Crawly.Request{url: "https://www.some_url.com"}
  setup do
    :meck.new(:test_spider, [:non_strict])
    :meck.expect(:test_spider, :base_url, fn -> "example.com" end)

    on_exit(fn ->
      Application.put_env(:crawly, :item_id, :title)
    end)
  end

  test "Filters out requests that do not contain a spider's base_url" do
    middlewares = [Crawly.Middlewares.DomainFilter]
    req = @valid
    state = %{spider_name: :test_spider}

    assert {false, _state} = Crawly.Utils.pipe(middlewares, req, state)
  end
end
