defmodule ManagerTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      Crawly.Engine.stop_spider(TestSpider)
    end)
  end

  test "Engine automatically tags a job on startup" do
    :ok = Crawly.Engine.start_spider(TestSpider)
    assert Crawly.Engine.get_crawl_id(TestSpider)
  end


  test "Engine will use a tag from external system if set" do
    tag = "custom_crawl_tag"
    :ok = Crawly.Engine.start_spider(TestSpider, tag)
    assert {:ok, tag} == Crawly.Engine.get_crawl_id(TestSpider)
  end
end