defmodule EngineTest do
  use ExUnit.Case

  test "list_spiders/0 lists all spiders and their current status in the engine" do
    assert spiders = Crawly.Engine.list_spiders()
    assert [_ | _] = spiders
    assert status = Enum.find(spiders, fn s -> s.name == TestSpider end)
    assert status.state == :stopped
    assert status.pid == nil

    # test a started spider
    Crawly.Engine.start_spider(TestSpider)

    assert started_status =
             Crawly.Engine.list_spiders()
             |> Enum.find(fn s -> s.name == TestSpider end)

    assert started_status.state == :started
    assert started_status.pid
  end

  test "stop_all_spiders/0 stops all spiders" do
    Crawly.Engine.list_spiders()
    |> Enum.each(fn %{name: name} ->
      Crawly.Engine.start_spider(name)
    end)

    Crawly.Engine.stop_all_spiders()

    statuses = Crawly.Engine.list_spiders()

    assert Enum.all?(statuses, fn status ->
             assert status.state == :stopped
             assert status.pid == nil
           end)
  end
end
