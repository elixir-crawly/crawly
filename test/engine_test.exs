defmodule EngineTest do
  use ExUnit.Case, async: false
  alias Crawly.Engine

  setup do
    on_exit(fn ->
      Engine.stop_spider(TestSpider)
    end)
  end

  test "list_known_spiders/0 lists all spiders and their current status in the engine" do
    Engine.init([])
    Engine.refresh_spider_list()
    spiders = Engine.list_known_spiders()
    assert [_ | _] = spiders
    assert status = Enum.find(spiders, fn s -> s.name == TestSpider end)
    assert status.status == :stopped

    # test a started spider
    Engine.start_spider(TestSpider)

    assert started_status =
             Engine.list_known_spiders()
             |> Enum.find(fn s -> s.name == TestSpider end)

    assert :started = started_status.status
    assert started_status.pid

    # stop spider
    Engine.stop_spider(TestSpider)
    spiders = Engine.list_known_spiders()
    assert Enum.all?(spiders, fn s -> s.status == :stopped end)
  end

  test "start_spider/2 with :name option creates a runtime spider using a template module" do
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider")

    assert [%{name: "Test Spider", status: :started, template: template}] =
             Engine.list_known_spiders()

    assert template == TestSpider
  end

  test "start_spider/1 without :name option automatically sets the spider's string name" do
    assert :ok = Engine.start_spider(TestSpider)

    # stringify the module name
    assert [%{name: "TestSpider", template: template}] =
             Engine.list_known_spiders()

    assert TestSpider == template
  end

  test "start_spider/2 without :name option returns error if existing name is taken" do
    assert :ok = Engine.start_spider(TestSpider)
    assert {:error, :already_started} = Engine.start_spider(TestSpider)
  end

  test "start_spider/2 with clashing :name option returns error" do
    assert :ok = Engine.start_spider(TestSpider, name: "SomeSpider")

    assert {:error, :already_started} =
             Engine.start_spider(TestSpider, name: "SomeSpider")
  end

  test "stop_spider/1 with string name stops spider with matching name" do
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider")

    assert :ok = Engine.stop_spider("Test Spider")
    assert [] = Engine.list_known_spiders()
  end

  test "stop_spider/1 with template name stops all spiders using that template" do
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider")
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider 2")
    assert Engine.list_known_spiders() |> length() == 2

    assert :ok = Engine.stop_spider(TestSpider)
    assert [] = Engine.list_known_spiders()
  end

  describe "crawl_id tagging" do
    test "get_crawl_id/1 can retrieve crawl_id of spider by module" do
      # creates a runtime spider with name "TestSpider"
      :ok = Engine.start_spider(TestSpider)
      assert Engine.get_crawl_id(TestSpider)
    end

    test "get_crawl_id/1 can retrieve crawl_id of spider by name" do
      :ok = Engine.start_spider(TestSpider, name: "myspider")
      assert Engine.get_crawl_id("myspider")
    end

    test "Engine will use a tag from external system if set" do
      tag = "custom_crawl_tag"
      :ok = Engine.start_spider(TestSpider, tag)
      assert {:ok, tag} == Engine.get_crawl_id(TestSpider)
    end
  end
end
