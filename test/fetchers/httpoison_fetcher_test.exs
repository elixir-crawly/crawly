defmodule Crawly.Fetchers.HTTPoisonFetcherTest do
  use Crawly.TestCase, async: false

  alias Crawly.Fetchers.HTTPoisonFetcher

  describe "options passed to HTTPoison" do
    setup do
      :meck.new(HTTPoison, [:passthrough])

      :meck.expect(HTTPoison, :get, fn url, headers, options ->
        {:ok, %{url: url, headers: headers, options: options}}
      end)

      on_exit(fn -> :meck.unload() end)
    end

    test "uses the default timeouts when the request sets none" do
      request = Crawly.Request.new("http://example.com")

      assert {:ok, %{options: options}} = HTTPoisonFetcher.fetch(request, [])
      assert options[:timeout] == 8_000
      assert options[:recv_timeout] == 5_000
    end

    test "request options override the defaults and are kept" do
      request =
        Crawly.Request.new("http://example.com", [],
          recv_timeout: 15_000,
          follow_redirect: true
        )

      assert {:ok, %{options: options}} = HTTPoisonFetcher.fetch(request, [])
      assert options[:timeout] == 8_000
      assert options[:recv_timeout] == 15_000
      assert options[:follow_redirect] == true
    end
  end

  test "gives up on a server that accepts the connection but never answers" do
    {:ok, listen} = :gen_tcp.listen(0, [:binary, active: false])
    {:ok, port} = :inet.port(listen)

    acceptor =
      spawn(fn ->
        {:ok, _socket} = :gen_tcp.accept(listen)
        Process.sleep(:infinity)
      end)

    :ok = :gen_tcp.controlling_process(listen, acceptor)
    on_exit(fn -> Process.exit(acceptor, :kill) end)

    request =
      Crawly.Request.new("http://127.0.0.1:#{port}/", [], recv_timeout: 300)

    assert {:error, %HTTPoison.Error{reason: :timeout}} =
             HTTPoisonFetcher.fetch(request, [])
  end
end
