defmodule APITest do
  use ExUnit.Case, async: false
  use Plug.Test

  @opts Crawly.API.Router.init([])

  setup do
    Crawly.Engine.stop_spider(TestSpider)

    on_exit(fn ->
      :meck.unload()

      :get
      |> conn("/spiders/TestSpider/stop", "")
      |> Crawly.API.Router.call(@opts)
    end)

    Crawly.SimpleStorage.delete(:spiders, "TestSpiderYML")
    Crawly.SimpleStorage.delete(:spiders, "TestSpiderYMLForEdit")
  end

  test "returns welcome" do
    conn =
      :get
      |> conn("/spiders", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "No spiders are currently running"
  end

  test "scheduling spiders" do
    conn =
      :get
      |> conn("/spiders/TestSpider/schedule", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Started!"

    Process.sleep(400)

    conn =
      :get
      |> conn("/spiders/TestSpider/stop", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Stopped!"
  end

  test "It's possible to get requests preview page" do
    conn =
      :get
      |> conn("/spiders/TestSpider/schedule", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Started!"

    conn =
      :get
      |> conn("/spiders/TestSpider/requests", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
  end

  test "It's possible to get /new page" do
    conn =
      :get
      |> conn("/new", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
  end

  test "/new returns 400 for invalid yml" do
    conn =
      :post
      |> conn("/new", %{"test" => 123})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 400
    assert String.contains?(conn.resp_body, "malformed yaml")
  end

  test "/new returns 400 based on json schema" do
    yml = """
      base_url: "i am not url"
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
          attribute: "href a"
    """

    conn =
      :post
      |> conn("/new", %{spider: yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 400

    assert String.contains?(
             conn.resp_body,
             "Required property name was not present"
           )

    assert String.contains?(conn.resp_body, "Expected to be a valid uri")
  end

  test "/new cant override existing spider" do
    yml = """
      name: TestSpider
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
          attribute: "href a"
    """

    conn =
      :post
      |> conn("/new", %{spider: yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 400

    assert String.contains?(
             conn.resp_body,
             "Spider with this name already exists. Try editing it instead of overriding"
           )
  end

  test "/new it's possible to create a new yml spider and see it" do
    yml = """
      name: TestSpiderYML
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
          attribute: "href a"
    """

    conn =
      :post
      |> conn("/new", %{spider: yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Redirect"
    assert conn.status == 302

    conn =
      :get
      |> conn("/new?spider_name=TestSpiderYML", "")
      |> Crawly.API.Router.call(@opts)

    assert String.contains?(conn.resp_body, "name: TestSpiderYML")

    assert String.contains?(
             conn.resp_body,
             "base_url: \"https://books.toscrape.com/\""
           )
  end

  test "/new allows to edit already created spider" do
    yml = """
      name: TestSpiderYMLForEdit
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
          attribute: "href a"
    """

    conn =
      :post
      |> conn("/new", %{spider: yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 302

    new_yml = """
      name: TestSpiderYMLForEdit
      base_url: "https://books.toscrape.com/"
      start_urls:
        - "https://other.page.com/1"
      fields:
        - name: title
          selector: ".title"
      links_to_follow:
        - selector: "a"
          attribute: "href a"
    """

    conn =
      :post
      |> conn("/new?spider_name=TestSpiderYMLForEdit", %{spider: new_yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Redirect"
    assert conn.status == 302

    conn =
      :get
      |> conn("/new?spider_name=TestSpiderYMLForEdit", "")
      |> Crawly.API.Router.call(@opts)

    assert String.contains?(conn.resp_body, "name: TestSpiderYMLForEdit")
    assert String.contains?(conn.resp_body, "https://other.page.com/1")
  end

  test "/spiders/:spider_name/logs/:crawl_id returns file if it exists" do
    :meck.expect(Crawly.Utils, :spider_log_path, fn _, _ ->
      "./test/fixtures/test_crawl123.log"
    end)

    conn =
      :get
      |> conn("/spiders/Test/logs/crawl123", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
  end

  test "/spiders/:spider_name/logs/:crawl_id returns 404 if no file exists" do
    conn =
      :get
      |> conn("/spiders/Test/logs/other_id", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 404
  end

  test "GET /spiders/:spider_name/items/:crawl_id returns 404 if WriteToFile pipeline is not set" do
    conn =
      :get
      |> conn("/spiders/test_spider/items/123", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 404
  end

  test "GET /spiders/:spider_name/items/:crawl_id returns 404 if WriteToFile pipeline has no folder" do
    :meck.expect(
      Application,
      :get_env,
      fn :crawly, :pipelines, [] ->
        [{Crawly.Pipelines.WriteToFile, [format: "csv"]}]
      end
    )

    conn =
      :get
      |> conn("/spiders/test_spider/items/123", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 404
  end

  test "GET /spiders/:spider_name/items/:crawl_id returns file" do
    :meck.expect(
      Application,
      :get_env,
      fn :crawly, :pipelines, [] ->
        [{Crawly.Pipelines.WriteToFile, [folder: "./test/fixtures"]}]
      end
    )

    conn =
      :get
      |> conn("/spiders/test_spider/items/id123", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
    assert conn.resp_body == "{\"title\": \"My book\", \"price\": 10}"
  end

  test "POST /yml-preview handles unparsable YML files" do
    yml = """
        >>name: invalid
    """

    conn =
      :post
      |> conn("/yml-preview", %{spider: yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "YamlElixir.ParsingError"
  end

  test "POST /yml-preview handles valid YML part without spider definitions" do
    yml = """
    just a binary
    """

    conn =
      :post
      |> conn("/yml-preview", %{spider: yml})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200

    assert conn.resp_body =~
             "%{error: \"Nothing can be extracted from YML code\"}"
  end

  test "POST /yml-preview works in case if Crawly.Utils.preview/1 gives correct response" do
    :meck.expect(
      Crawly.Utils,
      :preview,
      fn _ ->
        [
          %{
            url: "https://example.com",
            requests: ["https://example.com/1"],
            items: [%{}]
          }
        ]
      end
    )

    conn =
      :post
      |> conn("/yml-preview", %{spider: "yml"})
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200

    assert conn.resp_body =~
             "%{items: [%{}], requests: [\"https://example.com/1\"], url: \"https://example.com\"}"
  end
end
