defmodule EngineTest do
  use ExUnit.Case

  setup do
    Crawly.Engine.stop_spider(TestSpider)

    on_exit(fn ->
      :meck.unload()

      Crawly.Engine.list_known_spiders()
      |> Enum.each(fn s ->
        Crawly.Engine.stop_spider(s)
      end)
    end)
  end

  test "list_known_spiders/0 lists all spiders and their current status in the engine" do
    Crawly.Engine.refresh_spider_list()
    spiders = Crawly.Engine.list_known_spiders()
    assert [_ | _] = spiders

    status = Enum.find(spiders, fn s -> s.name == TestSpider end)
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

  test "get_spider_info/1 return the spider currently status in the engine" do
    Crawly.Engine.refresh_spider_list()

    spider_info = Crawly.Engine.get_spider_info(TestSpider)

    assert :stopped == spider_info.status

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)
    spider_info = Crawly.Engine.get_spider_info(TestSpider)
    assert :started = spider_info.status
    assert spider_info.pid

    # stop spider
    Crawly.Engine.stop_spider(TestSpider)
    spider_info = Crawly.Engine.get_spider_info(TestSpider)
    assert :stopped = spider_info.status
  end

  test ":log_to_file allows for logging to log file" do
    tmp_dir = System.tmp_dir!() |> Path.join("crawly_test_logs")
    crawl_id = "test_crawl_#{System.unique_integer([:positive])}"

    :meck.expect(TestSpider, :override_settings, fn ->
      [log_dir: tmp_dir, log_to_file: true]
    end)

    Crawly.Engine.refresh_spider_list()
    Crawly.Engine.start_spider(TestSpider, crawl_id: crawl_id)

    handler_id = :"crawly_TestSpider_#{crawl_id}"
    assert {:ok, config} = :logger.get_handler_config(handler_id)
    assert to_string(config.config.file) =~ tmp_dir
    assert to_string(config.config.file) =~ "TestSpider"

    Crawly.Engine.stop_spider(TestSpider)

    assert {:error, {:not_found, ^handler_id}} =
             :logger.get_handler_config(handler_id)
  end

  test ":logger handler is not added when log_to_file is disabled" do
    crawl_id = "no_log_#{System.unique_integer([:positive])}"

    :meck.expect(TestSpider, :override_settings, fn ->
      [log_to_file: false]
    end)

    Crawly.Engine.refresh_spider_list()
    Crawly.Engine.start_spider(TestSpider, crawl_id: crawl_id)

    handler_id = :"crawly_TestSpider_#{crawl_id}"

    assert {:error, {:not_found, ^handler_id}} =
             :logger.get_handler_config(handler_id)

    Crawly.Engine.stop_spider(TestSpider)
  end

  test ":logger handler is configured and added when log_to_file is enabled" do
    tmp_dir = System.tmp_dir!() |> Path.join("crawly_test_logs_enabled")
    crawl_id = "enabled_#{System.unique_integer([:positive])}"

    :meck.expect(TestSpider, :override_settings, fn ->
      [log_dir: tmp_dir, log_to_file: true]
    end)

    Crawly.Engine.refresh_spider_list()
    Crawly.Engine.start_spider(TestSpider, crawl_id: crawl_id)

    handler_id = :"crawly_TestSpider_#{crawl_id}"
    assert {:ok, config} = :logger.get_handler_config(handler_id)
    assert to_string(config.config.file) =~ tmp_dir

    Crawly.Engine.stop_spider(TestSpider)

    assert {:error, {:not_found, ^handler_id}} =
             :logger.get_handler_config(handler_id)
  end
end
