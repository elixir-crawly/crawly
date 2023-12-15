defmodule Crawly.Fetchers.CrawlyRenderServerTest do
  use ExUnit.Case
  import Crawly.Fetchers.CrawlyRenderServer

  test "throws an error when base_url is not set" do
    request = %{
      url: "https://example.com",
      headers: %{"User-Agent" => "Custom User Agent"}
    }

    client_options = []

    assert_raise RuntimeError, fn ->
      fetch(request, client_options)
    end
  end

  test "composes correct request to render server" do
    request = %{
      url: "https://example.com",
      headers: [{"User-Agent", "Custom User Agent"}],
      options: []
    }

    client_options = [base_url: "http://localhost:3000"]

    :meck.expect(HTTPoison, :post, fn base_url, body, headers, _options ->
      assert headers == [{"content-type", "application/json"}]
      assert base_url == "http://localhost:3000"

      body = Poison.decode!(body, %{keys: :atoms})
      assert "https://example.com" == body.url
      assert %{:"User-Agent" => "Custom User Agent"} == body.headers
    end)

    fetch(request, client_options)
  end
end
