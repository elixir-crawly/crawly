defmodule UtilsTest do
  use ExUnit.Case

  setup do
    on_exit(fn -> :meck.unload() end)

    :ok
  end

  test "Request from url" do
    requests = Crawly.Utils.request_from_url("https://test.com")
    assert requests == expected_request("https://test.com")
  end

  test "Requests from urls" do
    requests =
      Crawly.Utils.requests_from_urls([
        "https://test.com",
        "https://example.com"
      ])

    assert requests == [
             expected_request("https://test.com"),
             expected_request("https://example.com")
           ]
  end

  test "Build absolute url test" do
    url = Crawly.Utils.build_absolute_url("/url1", "http://example.com")
    assert url == "http://example.com/url1"
  end

  test "Build absolute urls test" do
    paths = ["/path1", "/path2"]
    result = Crawly.Utils.build_absolute_urls(paths, "http://example.com")

    assert result == ["http://example.com/path1", "http://example.com/path2"]
  end

  test "pipe with args" do
    # make mock pipeline
    :meck.new(FakePipeline, [:non_strict])

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state, args ->
        {item, Map.put(state, :args, args)}
      end
    )

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state ->
        {item, state}
      end
    )

    {_item, state} =
      Crawly.Utils.pipe([{FakePipeline, my: "arg"}], %{my: "item"}, %{})

    assert state.args == [my: "arg"]
  end

  test "pipe without args" do
    # make mock pipeline
    :meck.new(FakePipeline, [:non_strict])

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state, args ->
        {item, %{state | args: args}}
      end
    )

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state ->
        {item, state}
      end
    )

    {_item, state} = Crawly.Utils.pipe([FakePipeline], %{my: "item"}, %{})

    assert Map.has_key?(state, :args) == false
  end

  test "can find CrawlySpider behaviors" do
    assert Enum.any?(
             Crawly.Utils.list_spiders(),
             fn x -> x == UtilsTestSpider end
           )
  end

  describe "Extract Requests tests" do
    setup do
      html = """
        <html>
          <a href="/blog/">Blog</a>
          <a href="/shop">Shop</a>
          <a href="/shop/item/1">Item1</a>
          <a href="/shop/item/2">Item2</a>
          <a href="http://example.com/blog-page/2">Item2</a>
          <a href="https://other-site.com/blog-page/1">Other site</a>
          <a href="mailto:someone@examplesite.com">Email Us</a>
        </html>
      """

      {:ok, html: html}
    end

    test "Extract requests only matching a given filters", %{html: html} do
      base_url = "http://example.com"

      expected_requests =
        Crawly.Utils.requests_from_urls([
          "http://example.com/shop/item/1",
          "http://example.com/shop/item/2"
        ])

      assert Enum.sort(expected_requests) ==
               Enum.sort(
                 Crawly.Utils.extract_requests(html, base_url, ["/item/"])
               )
    end

    test "It's possible to extract requests from the page", %{html: html} do
      base_url = "http://example.com"

      expected_requests =
        Crawly.Utils.requests_from_urls([
          "http://example.com/shop/item/1",
          "http://example.com/shop/item/2"
        ])

      assert Enum.sort(expected_requests) ==
               Enum.sort(
                 Crawly.Utils.extract_requests(html, base_url, ["/item/"])
               )
    end

    test "multiple filters", %{html: html} do
      base_url = "http://example.com"

      expected_requests =
        Crawly.Utils.requests_from_urls([
          "http://example.com/shop/item/1",
          "http://example.com/shop/item/2",
          "http://example.com/blog/"
        ])

      assert Enum.sort(expected_requests) ==
               Enum.sort(
                 Crawly.Utils.extract_requests(html, base_url, [
                   "/item/",
                   "/blog/"
                 ])
               )
    end

    test "non http/https links are ignored", %{html: html} do
      base_url = "http://example.com"

      assert [] ==
               Crawly.Utils.extract_requests(html, base_url, ["examplesite"])
    end

    test "Works with absolute urls", %{html: html} do
      base_url = "http://example.com"

      expected_requests =
        Crawly.Utils.requests_from_urls([
          "http://example.com/blog-page/2"
        ])

      assert expected_requests ==
               Crawly.Utils.extract_requests(html, base_url, ["/blog-page/2"])
    end

    test "Works with absolute urls leading to other sites", %{html: html} do
      base_url = "http://example.com"

      expected_requests =
        Crawly.Utils.requests_from_urls([
          "https://other-site.com/blog-page/1"
        ])

      assert expected_requests ==
               Crawly.Utils.extract_requests(html, base_url, ["/blog-page/1"])
    end
  end

  defp expected_request(url) do
    %Crawly.Request{
      url: url,
      headers: [],
      options: [],
      middlewares: [
        Crawly.Middlewares.DomainFilter,
        Crawly.Middlewares.UniqueRequest,
        Crawly.Middlewares.RobotsTxt,
        {Crawly.Middlewares.UserAgent, user_agents: ["My Custom Bot"]}
      ],
      retries: 0
    }
  end
end
