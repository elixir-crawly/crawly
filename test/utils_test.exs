defmodule UtilsTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      System.delete_env("SPIDERS_DIR")
      :ok = Crawly.Utils.clear_registered_spiders()
      :meck.unload()
    end)

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

  test "load spiders returns result if SPIDERS_DIR is not set" do
    assert {:error, :no_spiders_dir} == Crawly.Utils.load_spiders()
  end

  test "Can load modules set in SPIDERS_DIR" do
    System.put_env("SPIDERS_DIR", "./examples/quickstart/lib/quickstart")
    {:ok, loaded_modules} = Crawly.Utils.load_spiders()

    assert Enum.sort([Quickstart.Application, BooksToScrape]) ==
             Enum.sort(loaded_modules)
  end

  test "Invalid module options format" do
    :meck.expect(
      Crawly.Utils,
      :get_settings,
      fn :fetcher, nil, nil ->
        {Crawly.Fetchers.HTTPoisonFetcher}
      end
    )

    assert catch_error(
             Crawly.Utils.get_settings(:fetcher, nil, nil)
             |> Crawly.Utils.unwrap_module_and_options()
           )
  end

  test "extract_requests Can extract requests from a given HTML document" do
    html = """
    <!doctype html>
      <html>
      <body>
        <section id="content">
          <p class="headline">Floki</p>
          <span class="headline">Enables search using CSS selectors</span>
          <a class="link" href="/philss/floki">Github page</a>
          <span data-model="user">philss</span>
        </section>
        <a href="https://hex.pm/packages/floki">Hex package</a>
      </body>
      </html>
    """

    {:ok, document} = Floki.parse_document(html)

    selectors =
      Poison.encode!([%{"selector" => "a.link", "attribute" => "href"}])

    [request] =
      Crawly.Utils.extract_requests(document, selectors, "https://github.com")

    assert "https://github.com/philss/floki" == request.url
  end

  test "extract_requests work with multiple selectors" do
    html = """
    <!doctype html>
      <html>
      <body>
        <section id="content">
          <p class="headline">Floki</p>
          <span class="headline">Enables search using CSS selectors</span>
          <a class="link" href="/philss/floki">Github page</a>
          <span data-model="user">philss</span>
        </section>
        <a class="hex" href="https://hex.pm/packages/floki">Hex package</a>
      </body>
      </html>
    """

    {:ok, document} = Floki.parse_document(html)

    selectors =
      Poison.encode!([
        %{"selector" => "a.hex", "attribute" => "href"},
        %{"selector" => "a.link", "attribute" => "href"}
      ])

    extracted_urls =
      Enum.map(
        Crawly.Utils.extract_requests(
          document,
          selectors,
          "https://github.com"
        ),
        fn request -> request.url end
      )

    expected_urls = [
      "https://github.com/philss/floki",
      "https://hex.pm/packages/floki"
    ]

    assert Enum.sort(expected_urls) == Enum.sort(extracted_urls)
  end

  test "extract_items Can extract items from a given document" do
    html = """
    <!doctype html>
      <html>
      <body>
        <section id="content">
          <p class="headline">Floki</p>
          <span class="body">Enables search using CSS selectors</span>
          <a class="link" href="/philss/floki">Github page</a>
          <span data-model="user">philss</span>
        </section>
        <a class="hex" href="https://hex.pm/packages/floki">Hex package</a>
      </body>
      </html>
    """

    {:ok, document} = Floki.parse_document(html)

    selectors =
      Poison.encode!([
        %{"selector" => ".headline", "name" => "title"},
        %{"selector" => "span.body", "name" => "body"}
      ])

    [item] = Crawly.Utils.extract_items(document, selectors)

    assert "Floki" == Map.get(item, "title")
    assert "Enables search using CSS selectors" == Map.get(item, "body")
  end

  test "Can load a spider from a YML format" do
    spider_yml = """
    name: BooksSpiderForTest
    base_url: "https://books.toscrape.com/"
    start_urls:
      - "https://books.toscrape.com/"
      - "https://books.toscrape.com/catalogue/a-light-in-the-attic_1000/index.html"
    fields:
      - name: title
        selector: ".headline"
      - name: body
        selector: ".body"
    links_to_follow:
      - selector: "a"
        attribute: "href"
    """

    Crawly.Utils.load_yml_spider(spider_yml)

    assert "https://books.toscrape.com/" == BooksSpiderForTest.base_url()

    assert [
             start_urls: [
               "https://books.toscrape.com/",
               "https://books.toscrape.com/catalogue/a-light-in-the-attic_1000/index.html"
             ]
           ] == BooksSpiderForTest.init()

    page_html = """
    <!doctype html>
      <html>
      <body>
        <section id="content">
          <p class="headline">Floki</p>
          <span class="body">Enables search using CSS selectors</span>
          <a class="link" href="/philss/floki">Github page</a>
          <span data-model="user">philss</span>
        </section>
        <a class="hex" href="https://hex.pm/packages/floki">Hex package</a>
      </body>
      </html>
    """

    response = %{body: page_html, request_url: "https://books.toscrape.com/"}
    parsed_item = BooksSpiderForTest.parse_item(response)

    urls_to_follow =
      Enum.map(Map.get(parsed_item, :requests), fn req -> req.url end)

    expected_urls = [
      "https://books.toscrape.com/philss/floki",
      "https://hex.pm/packages/floki"
    ]

    assert Enum.sort(expected_urls) == Enum.sort(urls_to_follow)

    assert [
             %{
               "body" => "Enables search using CSS selectors",
               "title" => "Floki",
               "url" => "https://books.toscrape.com/"
             }
           ] == Map.get(parsed_item, :items)
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
