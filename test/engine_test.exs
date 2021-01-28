defmodule EngineTest do
  use ExUnit.Case, async: false
  alias Crawly.Engine

  setup do
    on_exit(fn ->
      Engine.list_started_spiders()
      |> Enum.map(fn info ->
        Engine.stop_spider(info.name)
      end)
    end)
  end

  @name Atom.to_string(TestSpider)

  test "list_started_spiders/0 lists all spiders" do
    assert [] = Engine.list_started_spiders()
    Engine.start_spider(TestSpider)
    assert [started] = Engine.list_started_spiders()
    assert started.status == :initializing
    assert started.pid == nil
    assert :ok == Engine.stop_spider(TestSpider)
    :timer.sleep(50)
    assert [] = Engine.list_started_spiders()
  end

  test "list_spider_templates/0 lists all spider template modules" do
    Engine.refresh_spider_list()
    assert [TestSpider] = Engine.list_spider_templates()
  end

  test "get_spider_info/1 returns spider info if started" do
    assert nil == Engine.get_spider_info(TestSpider)
    Engine.start_spider(TestSpider)
    assert %{name: @name} = Engine.get_spider_info(@name)
    assert %{name: @name} = Engine.get_spider_info(TestSpider)
  end

  test "start_spider/2 with :name option creates a runtime spider using a template module" do
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider")

    assert [%{name: "Test Spider", template: template}] =
             Engine.list_started_spiders()

    assert template == TestSpider
  end

  test "start_spider/1 without :name option automatically sets the spider's string name" do
    assert :ok = Engine.start_spider(TestSpider)

    # stringify the module name
    assert [%{name: name, template: template}] = Engine.list_started_spiders()
    assert Atom.to_string(template) == name
    assert TestSpider == template
  end

  test "start_spider/2 without :name option returns error if existing name is taken" do
    assert :ok = Engine.start_spider(TestSpider)
    assert {:error, :spider_already_started} = Engine.start_spider(TestSpider)
  end

  test "start_spider/2 with clashing :name option returns error" do
    assert :ok = Engine.start_spider(TestSpider, name: "SomeSpider")

    assert {:error, :spider_already_started} =
             Engine.start_spider(TestSpider, name: "SomeSpider")
  end

  test "stop_spider/1 with string name stops spider with matching name" do
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider")
    :timer.sleep(100)
    assert :ok = Engine.stop_spider("Test Spider")
    :timer.sleep(100)
    assert [] = Engine.list_started_spiders()
  end

  test "stop_spider/1 with template name stops all spiders using that template" do
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider")
    assert :ok = Engine.start_spider(TestSpider, name: "Test Spider 2")
    assert Engine.list_started_spiders() |> length() == 2
    :timer.sleep(100)

    assert :ok = Engine.stop_spider(TestSpider)
    :timer.sleep(100)
    assert [] = Engine.list_started_spiders()
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

    test "can manually set crawl_id with other options" do
      tag = "custom_crawl_tag"
      :ok = Engine.start_spider(TestSpider, tag, name: "my_other_spider")
      assert {:ok, tag} == Engine.get_crawl_id("my_other_spider")
    end

    test "can manually set crawl_id option" do
      tag = "custom_crawl_tag"
      :ok = Engine.start_spider(TestSpider, crawl_id: tag)
      assert {:ok, tag} == Engine.get_crawl_id(TestSpider)
    end
  end
end
