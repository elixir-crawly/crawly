defmodule APITest do
  use ExUnit.Case, async: false
  use Plug.Test

  @opts Crawly.API.Router.init([])

  setup do
    Crawly.Engine.stop_spider(TestSpider)

    on_exit(fn ->
      :get
      |> conn("/spiders/TestSpider/stop", "")
      |> Crawly.API.Router.call(@opts)
    end)

    Crawly.SpidersStorage.delete("TestSpiderYML")
    Crawly.SpidersStorage.delete("TestSpiderYMLForEdit")
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

  test "It's possible to get preview page" do
    conn =
      :get
      |> conn("/spiders/TestSpider/schedule", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.resp_body == "Started!"

    conn =
      :get
      |> conn("/spiders/TestSpider/items", "")
      |> Crawly.API.Router.call(@opts)

    assert conn.status == 200
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
end
