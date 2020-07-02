defmodule ManagerTest do
  use ExUnit.Case, async: false

  alias Features.Manager.TestSpider

  setup do
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
    Application.put_env(:crawly, :closespider_itemcount, 10)
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)

    :meck.expect(HTTPoison, :get, fn _, _, _ ->
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: "Some page",
         headers: [],
         request: %{}
       }}
    end)

    on_exit(fn ->
      :meck.unload()
      Crawly.Engine.stop_spider(TestSpider)
      Application.put_env(:crawly, :manager_operations_timeout, 30_000)
      Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
      Application.put_env(:crawly, :closespider_timeout, 20)
      Application.put_env(:crawly, :closespider_itemcount, 100)
    end)
  end

  test "max request per minute is respected" do
    :ok = Crawly.Engine.start_spider(TestSpider)

    {:stored_requests, num} = Crawly.RequestsStorage.stats(TestSpider)
    assert num == 1
    Process.sleep(1_00)

    {:stored_items, num} = Crawly.DataStorage.stats(TestSpider)
    assert num == 1

    :ok = Crawly.Engine.stop_spider(TestSpider)
    assert %{} == Crawly.Engine.running_spiders()
  end

  test "Closespider itemcount is respected" do
    Process.register(self(), :spider_closed_callback_test)

    Application.put_env(:crawly, :manager_operations_timeout, 50)
    Application.put_env(:crawly, :closespider_itemcount, 1)
    :ok = Crawly.Engine.start_spider(TestSpider)

    assert_receive :itemcount_timeout

    assert %{} == Crawly.Engine.running_spiders()
  end

  test "Closespider timeout is respected" do
    Process.register(self(), :spider_closed_callback_test)

    # Ignore closespider_itemcount
    Application.put_env(:crawly, :closespider_itemcount, :disabled)

    Application.put_env(:crawly, :closespider_timeout, 10)

    Application.put_env(:crawly, :manager_operations_timeout, 50)
    :ok = Crawly.Engine.start_spider(TestSpider)

    assert_receive :itemcount_timeout
    assert %{} == Crawly.Engine.running_spiders()
  end

  test "Can't start already started spider" do
    :ok = Crawly.Engine.start_spider(TestSpider)

    assert {:error, :spider_already_started} ==
             Crawly.Engine.start_spider(TestSpider)
  end

  test "Spider closed callback is called when spider is stopped" do
    Process.register(self(), :spider_closed_callback_test)
    :ok = Crawly.Engine.start_spider(TestSpider)
    :ok = Crawly.Engine.stop_spider(TestSpider, :manual_stop)

    assert_receive :manual_stop
  end
end
