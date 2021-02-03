defmodule ManagerTest do
  use ExUnit.Case, async: false

  alias Crawly.Engine
  @spider_name "my_test_spider"
  setup do
    :meck.expect(Crawly.RequestsStorage.Worker, :pop, fn _pid ->
      Crawly.Request.new("http://example.com")
    end)

    :meck.expect(Crawly.Fetchers.HTTPoisonFetcher, :fetch, fn _request, _opt ->
      {:ok, %HTTPoison.Response{status_code: 200}}
    end)

    on_exit(fn ->
      Engine.list_started_spiders()
      |> Enum.each(fn info ->
        Engine.stop_spider(info.name, :stopped_by_on_exit)
      end)

      :meck.unload()
    end)

    :ok
  end

  test "manager does not crash with high number of urls" do
    urls =
      for i <- 0..800_000 do
        "https://www.example.com/#{i}"
      end

    assert :ok =
             Crawly.Engine.start_spider(TestSpider,
               name: @spider_name,
               start_urls: urls
             )

    :timer.sleep(200)
    assert %{status: :running} = Crawly.Engine.get_spider_info(@spider_name)
  end

  test "it is possible to add/remove workers to a spider" do
    Crawly.Engine.start_spider(TestSpider,
      name: @spider_name,
      concurrent_requests_per_domain: 1,
      closespider_itemcount: :disabled,
      closespider_timeout: :disabled
    )

    :timer.sleep(100)

    assert %{workers: 1, status: :running} =
             Crawly.Engine.get_spider_info(@spider_name)

    assert :ok == Crawly.Manager.add_workers(@spider_name, 2)
    assert %{workers: 3} = Crawly.Engine.get_spider_info(@spider_name)
  end

  test "returns error when spider doesn't exist" do
    assert {:error, :spider_not_found} ==
             Crawly.Manager.add_workers(Manager.NonExistentSpider, 2)
  end

  describe "spider stop reason" do
    setup do
      :meck.expect(TestSpider, :override_settings, fn ->
        [
          on_spider_closed_callback: fn reason ->
            :persistent_term.put(:spider_stop_reason, reason)
          end
        ]
      end)

      on_exit(fn ->
        :persistent_term.erase(:spider_stop_reason)
      end)
    end

    test "Closespider itemcount is respected" do
      :meck.expect(Crawly.DataStorage, :stats, fn _ -> {:stored_items, 5} end)

      Crawly.Engine.start_spider(TestSpider,
        name: @spider_name,
        closespider_itemcount: 1,
        closespider_timeout: :disabled
      )

      Process.sleep(1000)

      assert :persistent_term.get(:spider_stop_reason) ==
               :itemcount_limit
    end

    test "Closespider timeout is respected" do
      Crawly.Engine.start_spider(TestSpider, closespider_itemcount: :disabled)
      Process.sleep(1000)
      assert :persistent_term.get(:spider_stop_reason) == :itemcount_timeout
    end

    test "Spider closed callback is called when spider is stopped" do
      Crawly.Engine.start_spider(TestSpider, name: @spider_name)
      :timer.sleep(100)
      Crawly.Engine.stop_spider(@spider_name, :manual_stop)
      :timer.sleep(100)
      assert :persistent_term.get(:spider_stop_reason) == :manual_stop
    end

    test "It's possible to start a spider with start_requests" do
      pid = self()

      :meck.expect(Crawly.RequestsStorage, :store, fn _spider, request ->
        send(pid, {:performing_request, request})
      end)

      :ok =
        Crawly.Engine.start_spider(TestSpider,
          name: @spider_name,
          closespider_itemcount: :disabled,
          closespider_timeout: :disabled
        )

      Process.sleep(100)
      assert_receive {:performing_request, req}
      assert req.url == "https://www.example.com/blog.html"
    end
  end
end
