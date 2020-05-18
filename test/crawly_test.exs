defmodule CrawlyTest do
  use ExUnit.Case
  doctest Crawly

  setup do
    :meck.new(CrawlyTestSpider)

    :meck.expect(CrawlyTestSpider, :parse_items, fn resp ->
      %{
        items: ["hello"],
        requests: [
          Crawly.Utils.request_from_url("https://www.example.com/test")
        ]
      }
    end)

    on_exit(fn ->
      :meck.unload(CrawlyTestSpider)
    end)
  end

  test "fetch/1 is able to fetch a given url using global config, returns a response" do
    assert %HTTPoison.Response{} = Crawly.fetch("https://example.com")
  end

  test "fetch/2 with :with option provided returns the response, parsed_item result, and processed ParsedItems" do
    assert {%HTTPoison.Response{}, parsed_items_res, parsed_items} =
             Crawly.fetch("http://example.com", with: CrawlyTestSpider)

    assert %{
             items: items,
             requests: requests
           } = parsed_items_res

    assert is_list(parsed_items)
    assert length(parsed_items) == 1
    assert ["hello"] = parsed_items
  end
end
