defmodule EngineTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      Crawly.Engine.stop_spider(TestSpider)
    end)
  end

  test "list_known_spiders/0 lists all spiders and their current status in the engine" do
    Crawly.Engine.init([])
    Crawly.Engine.refresh_spider_list()
    spiders = Crawly.Engine.list_known_spiders()
    assert [_ | _] = spiders
    assert status = Enum.find(spiders, fn s -> s.name == TestSpider end)
    assert status.status == :stopped

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)

    assert started_status =
             Crawly.Engine.list_known_spiders()
             |> Enum.find(fn s -> s.name == TestSpider end)

    assert :started = started_status.status
    assert started_status.pid

    # stop spider
    Crawly.Engine.stop_spider(TestSpider)
    spiders = Crawly.Engine.list_known_spiders()
    assert Enum.all?(spiders, fn s -> s.status == :stopped end)
  end

  test "start_spider/2 with :name option creates a runtime spider using a template module" do
    assert :ok = Crawly.Engine.start_spider(TestSpider, name: "Test Spider")

    assert [%{name: "Test Spider", status: :started, template: template}] =
             Crawly.Engine.list_known_spiders()

    assert template == TestSpider
  end

  test "start_spider/1 without :name option automatically sets the spider's string name" do
    assert :ok = Crawly.Engine.start_spider(TestSpider)

    # stringify the module name
    assert [%{name: "TestSpider", template: ^TestSpider}] =
             Crawly.Engine.list_known_spiders()
  end

  test "start_spider/2 without :name option returns error if existing name is taken" do
    assert :ok = Crawly.Engine.start_spider(TestSpider)
    assert {:error, :already_started} = Crawly.Engine.start_spider(TestSpider)
  end

  test "start_spider/2 with clashing :name option returns error" do
    assert :ok = Crawly.Engine.start_spider(TestSpider, name: "SomeSpider")

    assert {:error, :already_started} =
             Crawly.Engine.start_spider(TestSpider, name: "SomeSpider")
  end

  test "stop_spider/1 with string name stops spider with matching name" do
    assert :ok = Crawly.Engine.start_spider(TestSpider, name: "Test Spider")

    assert :ok = Crawly.Engine.stop_spider("Test Spider")
    assert [] = Crawly.Engine.list_known_spiders()
  end

  test "stop_spider/1 with template name stops all spiders using that template" do
    assert :ok = Crawly.Engine.start_spider(TestSpider, name: "Test Spider")
    assert :ok = Crawly.Engine.start_spider(TestSpider, name: "Test Spider 2")
    assert Crawly.Engine.list_known_spiders() |> length() == 2

    assert :ok = Crawly.Engine.stop_spider(TestSpider)
    assert [] = Crawly.Engine.list_known_spiders()
  end

  describe "crawl_id tagging" do
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
end
