defmodule ManagerTest do
  use ExUnit.Case, async: false

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
      Crawly.Engine.stop_spider(Manager.TestSpider)
      Application.put_env(:crawly, :manager_operations_timeout, 30_000)
      Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
      Application.put_env(:crawly, :closespider_timeout, 20)
      Application.put_env(:crawly, :closespider_itemcount, 100)
    end)
  end

  test "max request per minute is respected" do
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)

    {:stored_requests, num} = Crawly.RequestsStorage.stats(Manager.TestSpider)
    assert num == 1
    Process.sleep(1_00)

    {:stored_items, num} = Crawly.DataStorage.stats(Manager.TestSpider)
    assert num == 1

    :ok = Crawly.Engine.stop_spider(Manager.TestSpider)
    assert %{} == Crawly.Engine.running_spiders()
  end

  test "Closespider itemcount is respected" do
    Process.register(self(), :spider_closed_callback_test)

    Application.put_env(:crawly, :manager_operations_timeout, 50)
    Application.put_env(:crawly, :closespider_itemcount, 1)
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)

    assert_receive :itemcount_timeout

    assert %{} == Crawly.Engine.running_spiders()
  end

  test "Closespider timeout is respected" do
    Process.register(self(), :spider_closed_callback_test)

    # Ignore closespider_itemcount
    Application.put_env(:crawly, :closespider_itemcount, :disabled)

    Application.put_env(:crawly, :closespider_timeout, 10)

    Application.put_env(:crawly, :manager_operations_timeout, 50)
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)

    assert_receive :itemcount_timeout
    assert %{} == Crawly.Engine.running_spiders()
  end

  test "Can't start already started spider" do
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)

    assert {:error, :spider_already_started} ==
             Crawly.Engine.start_spider(Manager.TestSpider)
  end

  test "Spider closed callback is called when spider is stopped" do
    Process.register(self(), :spider_closed_callback_test)
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)
    :ok = Crawly.Engine.stop_spider(Manager.TestSpider, :manual_stop)

    assert_receive :manual_stop
  end
end

defmodule Manager.TestSpider do
  use Crawly.Spider

  def override_settings() do
    on_spider_closed_callback = fn reason ->
      case Process.whereis(:spider_closed_callback_test) do
        nil ->
          :nothing_to_do

        _pid ->
          send(:spider_closed_callback_test, reason)
      end
    end

    [on_spider_closed_callback: on_spider_closed_callback]
  end

  def base_url() do
    "https://www.example.com"
  end

  def init() do
    [
      start_urls: ["https://www.example.com/blog.html"]
    ]
  end

  def parse_item(_response) do
    path = Enum.random(1..100)

    %{
      :items => [
        %{title: "t_#{path}", url: "example.com", author: "Me", time: "not set"}
      ],
      :requests => [
        Crawly.Utils.request_from_url("https://www.example.com/#{path}")
      ]
    }
  end

  def spider_closed(:manual_stop) do
    send(:spider_closed_callback_test, :manual_stop)
  end

  def spider_closed(_) do
    :ignored
  end
end
