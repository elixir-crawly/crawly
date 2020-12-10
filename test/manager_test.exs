defmodule ManagerTest do
  use ExUnit.Case, async: false

  alias Crawly.Engine

  setup do
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
    Application.put_env(:crawly, :closespider_itemcount, 10)

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
      Engine.running_spiders()
      |> Map.keys()
      |> Enum.each(&Engine.stop_spider/1)

      :meck.unload()

      Application.put_env(:crawly, :manager_operations_timeout, 30_000)
      Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
      Application.put_env(:crawly, :closespider_timeout, 20)
      Application.put_env(:crawly, :closespider_itemcount, 100)
    end)
  end

  test "manager does not crash with high number of urls" do
    assert :ok = Crawly.Engine.start_spider(Manager.ManyUrlsTestSpider)
  end

  test "it is possible to add more workers to a spider" do
    spider_name = Manager.TestSpider
    :ok = Crawly.Engine.start_spider(spider_name)
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

  test "spider does not close after 1 minute when closespider timeout is disabled" do
    Application.put_env(:crawly, :closespider_timeout, :disabled)
    Application.put_env(:crawly, :manager_operations_timeout, 1_000)

    :ok = Crawly.Engine.start_spider(Manager.TestSpider)

    Process.sleep(1_001)

    refute %{} == Crawly.Engine.running_spiders()

    :ok = Crawly.Engine.stop_spider(Manager.TestSpider)
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

  test "It's possible to start a spider with start_requests" do
    pid = self()
    :ok = Crawly.Engine.start_spider(Manager.StartRequestsTestSpider)

    :meck.expect(HTTPoison, :get, fn url, _, _ ->
      send(pid, {:performing_request, url})

      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: "Some page",
         headers: [],
         request: %{}
       }}
    end)

    assert_receive {:performing_request, "https://www.example.com/blog.html"}
  end

  test "It's possible to initialize a spider with parameters" do
    Process.register(self(), :manager_test_initial_args_test)

    urls = [
      "https://example.com/1",
      "https://example.com/2",
      "https://example.com/3"
    ]

    :ok = Crawly.Engine.start_spider(Manager.InitialArgsTestSpider, urls: urls)

    assert_receive recv_opts
    assert is_binary(recv_opts[:crawl_id])
    assert Enum.sort(recv_opts[:urls]) == Enum.sort(urls)
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

defmodule Manager.InitialArgsTestSpider do
  use Crawly.Spider

  def base_url() do
    "https://www.example.com"
  end

  def init(opts) do
    send(:manager_test_initial_args_test, opts)
    [start_urls: opts[:urls]]
  end

  def parse_item(_response) do
    %{items: [], requests: []}
  end
end

defmodule Manager.ManyUrlsTestSpider do
  use Crawly.Spider

  def base_url() do
    "https://www.example.com"
  end

  def init(_opts) do
    urls =
      for i <- 0..50_000 do
        "https://www.example.com/#{i}"
      end

    requests =
      for i <- 0..50_000 do
        Crawly.Request.new("https://www.example.com/x/#{i}")
      end

    [start_requests: requests, start_urls: urls]
  end

  def parse_item(_response) do
    %{items: [], requests: []}
  end
end
