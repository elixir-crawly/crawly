defmodule EngineTest do
  use ExUnit.Case

  setup do
    stop_all()
    on_exit(&stop_all/0)
  end

  defp stop_all do
    Crawly.Utils.list_spiders()
    |> Enum.each(fn s -> Crawly.Engine.stop_spider(s) end)
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
             Crawly.Engine.list_spiders()
             |> Enum.find(fn s -> s.name == TestSpider end)

    assert started_status.state == :started
    assert started_status.pid
  end

  test "start_all_spiders/0 starts all spiders in the engine" do
    assert :ok = Crawly.Engine.start_all_spiders()
    statuses = Crawly.Engine.list_spiders()

    assert Enum.all?(statuses, fn status ->
             status.state == :started and not is_nil(status.pid)
           end)

    Crawly.Engine.list_known_spiders()
    |> Enum.find(fn s -> s.name == TestSpider end)

    assert :started = started_status.status
    assert started_status.pid

    # stop spider
    Crawly.Engine.stop_spider(TestSpider)
    spiders = Crawly.Engine.list_known_spiders()
    assert Enum.all?(spiders, fn s -> s.status == :stopped end)
  end
end
