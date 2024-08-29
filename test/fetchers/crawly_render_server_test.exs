defmodule Crawly.Fetchers.CrawlyRenderServerTest do
  use ExUnit.Case

  alias Crawly.Fetchers.CrawlyRenderServer

  test "throws an error when base_url is not set" do
    request = %{
      url: "https://example.com",
      headers: %{"User-Agent" => "Custom User Agent"}
    }

    client_options = []

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        assert_raise RuntimeError, fn ->
          CrawlyRenderServer.fetch(request, client_options)
        end
      end)

    assert log =~
             "The base_url is not set. CrawlyRenderServer can't be used! Please set :base_url"
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

    CrawlyRenderServer.fetch(request, client_options)
  end
end
