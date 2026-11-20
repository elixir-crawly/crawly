defmodule LocalBooks.BooksSpiderTest do
  use ExUnit.Case, async: true

  alias LocalBooks.BooksSpider

  @site Path.expand("../../../test/e2e/site/html", __DIR__)

  test "extracts the 20 books and the next page from a catalogue page" do
    url = "http://localhost:8080/catalogue/page-2.html"

    response = %HTTPoison.Response{
      status_code: 200,
      body: File.read!(Path.join(@site, "catalogue/page-2.html")),
      request_url: url,
      request: %HTTPoison.Request{url: url}
    }

    %{items: items, requests: [next]} = BooksSpider.parse_item(response)

    assert length(items) == 20
    assert Enum.all?(items, &(&1.title != "" and &1.price =~ "£"))
    assert next.url == "http://localhost:8080/catalogue/page-3.html"
  end
end
