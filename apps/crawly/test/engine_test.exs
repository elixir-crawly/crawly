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

    assert status =
             Enum.find(spiders, fn s -> s.name == TestSpider end)

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

    spider_info =
      Crawly.Engine.get_spider_info(TestSpider)

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
    :meck.expect(TestSpider, :override_settings, fn ->
      [log_dir: "/my_tmp_dir", log_to_file: true]
    end)

    :meck.expect(Logger, :configure_backend, fn {_, :debug}, opts ->
      log_file_path = Keyword.get(opts, :path)
      assert log_file_path =~ "TestSpider"
      assert log_file_path =~ "/my_tmp_dir"
    end)

    Crawly.Engine.refresh_spider_list()

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)

    assert :meck.num_calls(Logger, :configure_backend, :_) == 1
  end

  test "LoggerFileBackend is not configured when module is not loaded" do
    :meck.expect(TestSpider, :override_settings, fn ->
      [log_dir: "/my_tmp_dir", log_to_file: true]
    end)

    :meck.expect(Crawly.Utils, :ensure_loaded?, fn _ ->
      false
    end)

    :meck.expect(Logger, :configure_backend, fn {_, :debug}, opts ->
      log_file_path = Keyword.get(opts, :path)
      assert log_file_path =~ "TestSpider"
      assert log_file_path =~ "/my_tmp_dir"
    end)

    Crawly.Engine.refresh_spider_list()

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)
    assert :meck.num_calls(Logger, :configure_backend, :_) == 0
  end

  test "LoggerFileBackend is configured when module is loaded" do
    :meck.expect(TestSpider, :override_settings, fn ->
      [log_dir: "/my_tmp_dir", log_to_file: true]
    end)

    :meck.expect(Crawly.Utils, :ensure_loaded?, fn _ ->
      true
    end)

    :meck.expect(Logger, :configure_backend, fn {_, :debug}, opts ->
      log_file_path = Keyword.get(opts, :path)
      assert log_file_path =~ "TestSpider"
      assert log_file_path =~ "/my_tmp_dir"
    end)

    Crawly.Engine.refresh_spider_list()

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)
    assert :meck.num_calls(Logger, :configure_backend, :_) == 1
  end
end
