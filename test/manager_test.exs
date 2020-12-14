defmodule ManagerTest do
  use ExUnit.Case, async: false

  alias Crawly.Engine

  setup do
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
      |> Enum.each(fn spider ->
        Engine.stop_spider(spider, :stopped_by_on_exit)
      end)

      :meck.unload()
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

    Process.sleep(250)
    {:stored_requests, num} = Crawly.RequestsStorage.stats(Manager.TestSpider)
    assert num == 1
  end

  test "Closespider itemcount is respected" do
    Process.register(self(), :spider_closed_callback_test)
    :ok = Crawly.Engine.start_spider(Manager.TestSpider)
    Process.sleep(501)
    assert_receive :itemcount_limit
  end

  test "Closespider timeout is respected" do
    Process.register(self(), :close_by_timeout_listener)

    :ok = Crawly.Engine.start_spider(Manager.CloseByTimeoutSpider)
    Process.sleep(501)
    assert_receive :itemcount_timeout
  end

  #

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

    [
      on_spider_closed_callback: on_spider_closed_callback,
      concurrent_requests_per_domain: 1,
      closespider_itemcount: 1,
      closespider_timeout: :disabled
    ]
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

defmodule Manager.CloseByTimeoutSpider do
  use Crawly.Spider

  def override_settings() do
    on_spider_closed_callback = fn reason ->
      IO.puts("Stopped #{reason}")

      case Process.whereis(:close_by_timeout_listener) do
        nil ->
          :nothing_to_do

        _pid ->
          send(:close_by_timeout_listener, reason)
      end
    end

    [
      on_spider_closed_callback: on_spider_closed_callback,
      closespider_timeout: 1,
      concurrent_requests_per_domain: 1
    ]
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
      for i <- 0..400_000 do
        "https://www.example.com/#{i}"
      end

    requests =
      for i <- 0..400_000 do
        Crawly.Request.new("https://www.example.com/x/#{i}")
      end

    [start_requests: requests, start_urls: urls]
  end

  def parse_item(_response) do
    %{items: [], requests: []}
  end
end
