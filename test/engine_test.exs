defmodule EngineTest do
  use ExUnit.Case

  setup do
    on_exit(fn ->
      :meck.unload()

      Crawly.Engine.list_known_spiders()
      |> Enum.each(fn s ->
        Crawly.Engine.stop_spider(s)
      end)
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

  test ":log_to_file allows for logging to log file" do
    :meck.expect(TestSpider, :override_settings, fn ->
      [log_dir: "/my_tmp_dir", log_to_file: true]
    end)

    :meck.expect(Logger, :configure_backend, fn {_, :debug}, opts ->
      log_file_path = Keyword.get(opts, :path)
      assert log_file_path =~ "TestSpider"
      assert log_file_path =~ "/my_tmp_dir"
    end)

    Crawly.Engine.init([])
    Crawly.Engine.refresh_spider_list()

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)

    assert :meck.num_calls(Logger, :configure_backend, :_) == 1
  end
end
