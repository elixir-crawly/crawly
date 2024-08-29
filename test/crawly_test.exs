defmodule CrawlyTest do
  use ExUnit.Case

  describe "fetch/1" do
    test "can fetch a given url" do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{}}
      end)

      assert {:ok, %HTTPoison.Response{}} = Crawly.fetch("https://example.com")
    end

    test "returns error if unable to fetch the page" do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:error, %HTTPoison.Error{}}
      end)

      assert {:error, %HTTPoison.Error{}} = Crawly.fetch("invalid-url")
    end

    test "can fetch a given url with custom request options" do
      request_opts = [timeout: 5000, recv_timeout: 5000]

      :meck.expect(HTTPoison, :get, fn _, _, passed_request_opts ->
        assert passed_request_opts == request_opts
        {:ok, %HTTPoison.Response{}}
      end)

      assert {:ok, %HTTPoison.Response{}} =
               Crawly.fetch("https://example.com", request_opts: request_opts)
    end

    test "can fetch a given url with headers" do
      headers = [{"Authorization", "Bearer token"}]

      :meck.expect(HTTPoison, :get, fn _, headers_opts, _ ->
        assert headers == headers_opts
        {:ok, %HTTPoison.Response{}}
      end)

      assert {:ok, %HTTPoison.Response{}} =
               Crawly.fetch("https://example.com", headers: headers)
    end
  end

  describe "fetch_with_spider/3" do
    test "Can fetch a given url from behalf of the spider" do
      expected_new_requests = [
        Crawly.Utils.request_from_url("https://www.example.com")
      ]

      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok, %HTTPoison.Response{}}
      end)

      :meck.new(CrawlyTestSpider, [:non_strict])

      :meck.expect(CrawlyTestSpider, :parse_item, fn _resp ->
        %{
          items: [%{content: "hello"}],
          requests: expected_new_requests
        }
      end)

      %{requests: requests, items: items} =
        Crawly.fetch_with_spider("https://example.com", CrawlyTestSpider)

      assert items == [%{content: "hello"}]
      assert requests == expected_new_requests
    end
  end
end
