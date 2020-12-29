defmodule ManagerTest do
  use ExUnit.Case, async: false

  alias Crawly.Engine

  setup do
    :meck.expect(Crawly.RequestsStorage.Worker, :pop, fn _pid ->
      Crawly.Request.new("http://example.com")
    end)

    :meck.expect(Crawly.Fetchers.HTTPoisonFetcher, :fetch, fn _request, _opt ->
      {:ok, %HTTPoison.Response{status_code: 200}}
    end)

    on_exit(fn ->
      Engine.running_spiders()
      |> Map.keys()
      |> Enum.each(fn spider ->
        Engine.stop_spider(spider, :stopped_by_on_exit)
      end)

      :persistent_term.erase(:spider_stop_reason)
      :meck.unload()
    end)
  end

  test "manager does not crash with high number of urls" do
    urls =
      for i <- 0..800_000 do
        "https://www.example.com/#{i}"
      end

    assert :ok =
             Crawly.Engine.start_spider(Manager.TestSpider, start_urls: urls)
  end

  test "it is possible to add more workers to a spider" do
    spider_name = Manager.TestSpider

    :ok =
      Crawly.Engine.start_spider(spider_name,
        crawl_id: "add_workers_test",
        concurrent_requests_per_domain: 1
      )

    initial_number_of_workers = 1

    assert initial_number_of_workers ==
             DynamicSupervisor.count_children(spider_name)[:workers]

    workers = 2
    assert :ok == Crawly.Manager.add_workers(spider_name, workers)

    pid = Crawly.Engine.get_manager(spider_name)
    state = :sys.get_state(pid)
    assert spider_name == state.name

    assert initial_number_of_workers + workers ==
             DynamicSupervisor.count_children(spider_name)[:workers]
  end

  test "returns error when spider doesn't exist" do
    assert {:error, :spider_not_found} ==
             Crawly.Manager.add_workers(Manager.NonExistentSpider, 2)
  end

  test "Closespider itemcount is respected" do
    :meck.expect(Crawly.DataStorage, :stats, fn _ -> {:stored_items, 5} end)

    :ok =
      Crawly.Engine.start_spider(Manager.TestSpider,
        closespider_itemcount: 1,
        closespider_timeout: :disabled
      )

    Process.sleep(700)
    assert :persistent_term.get(:spider_stop_reason) == :itemcount_limit
  end

  test "Closespider timeout is respected" do
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)
    Process.sleep(600)
    assert :persistent_term.get(:spider_stop_reason) == :itemcount_timeout
  end

  test "Can't start already started spider" do
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)

    assert {:error, :spider_already_started} ==
             Crawly.Engine.start_spider(Manager.TestSpider)
  end

  test "Spider closed callback is called when spider is stopped" do
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)
    :ok = Crawly.Engine.stop_spider(Manager.TestSpider, :manual_stop)
    assert :persistent_term.get(:spider_stop_reason) == :manual_stop
  end

  test "It's possible to start a spider with start_requests" do
    pid = self()

    :meck.expect(Crawly.RequestsStorage, :store, fn _spider, request ->
      send(pid, {:performing_request, request})
    end)

    :ok =
      Crawly.Engine.start_spider(Manager.StartRequestsTestSpider,
        closespider_itemcount: :disabled,
        closespider_timeout: :disabled
      )

    Process.sleep(100)
    assert_receive {:performing_request, req}
    assert req.url == "https://www.example.com/blog.html"
  end
end

defmodule Manager.TestSpider do
  use Crawly.Spider

  def override_settings() do
    [
      on_spider_closed_callback: fn _spider_name, _crawl_id, reason ->
        :persistent_term.put(:spider_stop_reason, reason)
      end
    ]
  end

  def base_url() do
    "https://www.example.com"
  end

  def init(opts) do
    start_urls =
      Keyword.get(opts, :start_urls, ["https://www.example.com/blog.html"])

    [start_urls: start_urls]
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
end

defmodule Manager.StartRequestsTestSpider do
  use Crawly.Spider

  def base_url() do
    "https://www.example.com"
  end

  def init() do
    [
      start_requests: [
        Crawly.Request.new("https://www.example.com/blog.html"),
        "Incorrect request"
      ]
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
end
