defmodule CrawlyTest do
  use ExUnit.Case

  setup do
    :meck.new(CrawlyTestSpider, [:non_strict])

    :meck.expect(CrawlyTestSpider, :parse_item, fn _resp ->
      %{
        items: [%{content: "hello"}],
        requests: [
          Crawly.Utils.request_from_url("https://www.example.com/test")
        ]
      }
    end)

    :meck.expect(CrawlyTestSpider, :override_settings, fn ->
      [pipelines: [Crawly.Pipelines.JSONEncoder]]
    end)

    on_exit(fn ->
      :meck.unload()
    end)

    {:ok, spider_module: CrawlyTestSpider}
  end

  test "fetch/1 is able to fetch a given url using global config, returns a response" do
    assert %HTTPoison.Response{} = Crawly.fetch("https://example.com")
  end

  test "fetch/2 with :with option provided returns the response, parsed_item result, and processed ParsedItems",
       %{spider_module: spider_module} do
    assert {%HTTPoison.Response{}, parsed_item_res, parsed_items,
            pipeline_state} =
             Crawly.fetch("http://example.com", with: spider_module)

    assert %{
             items: [_],
             requests: requests
           } = parsed_item_res

    assert [encoded] = parsed_items
    assert encoded =~ "hello"
  end
end
