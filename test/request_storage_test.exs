defmodule RequestStorageTest do
  use ExUnit.Case, async: false

  setup_all do
    :meck.new(:test_spider, [:non_strict])
    :meck.expect(:test_spider, :base_url, fn -> "example.com" end)
    :ok
  end

  setup do
    {:ok, pid} = Crawly.RequestsStorage.start_worker(:test_spider)

    on_exit(fn ->
      :ok =
        DynamicSupervisor.terminate_child(
          Crawly.RequestsStorage.WorkersSup,
          pid
        )

      # :ok = Crawly.RequestsStorage.WorkerSup.terminate_child(pid)
    end)

    {:ok, %{crawler: :test_spider}}
  end

  test "Request storage can store requests", context do
    request = Crawly.Request.new("http://example.com")

    :ok = Crawly.RequestsStorage.store(context.crawler, request)
    {:stored_requests, num} = Crawly.RequestsStorage.stats(context.crawler)
    assert 1 == num
  end

  test "Request storage returns request for given spider", context do
    request = Crawly.Request.new("http://example.com")
    :ok = Crawly.RequestsStorage.store(context.crawler, request)

    returned_request = Crawly.RequestsStorage.pop(context.crawler)
    assert request.url == returned_request.url
  end

  test "Correct error returned if there are no requests in storage", context do
    assert nil == Crawly.RequestsStorage.pop(context.crawler)
  end

  test "Error for unknown spiders (storages)" do
    assert {:error, :storage_worker_not_running} ==
             Crawly.RequestsStorage.pop(:unkown)

    assert {:error, :storage_worker_not_running} ==
             Crawly.RequestsStorage.stats(:unkown)

    assert {:error, :storage_worker_not_running} ==
             Crawly.RequestsStorage.store(%{}, :unkown)
  end

  test "Duplicated requests are filtered out", context do
    request = Crawly.Request.new("http://example.com")
    :ok = Crawly.RequestsStorage.store(context.crawler, request)
    :ok = Crawly.RequestsStorage.store(context.crawler, request)

    {:stored_requests, num} = Crawly.RequestsStorage.stats(context.crawler)
    assert 1 == num
  end

  test "Stopped workers are removed from request storage state", _context do
    {:ok, pid} = Crawly.RequestsStorage.start_worker(:other)
    state = :sys.get_state(Process.whereis(Crawly.RequestsStorage))
    assert Enum.count(state.pid_spiders) == 2
    assert Enum.count(state.workers) == 2

    TestUtils.stop_process(pid)

    state = :sys.get_state(Process.whereis(Crawly.RequestsStorage))
    assert Enum.count(state.pid_spiders) == 1
    assert Enum.count(state.workers) == 1
  end

  test "Outbound requests are filtered out", context do
    request = Crawly.Request.new("http://otherdomain.com")

    :ok = Crawly.RequestsStorage.store(context.crawler, request)
    {:stored_requests, num} = Crawly.RequestsStorage.stats(context.crawler)
    assert 0 == num
  end

  test "Robots.txt is respected", context do
    request = Crawly.Request.new("http://example.com/filter")

    :meck.expect(Gollum, :crawlable?, fn _, "http://example.com/filter" ->
      :uncrawlable
    end)

    :ok = Crawly.RequestsStorage.store(context.crawler, request)
    {:stored_requests, num} = Crawly.RequestsStorage.stats(context.crawler)
    assert 0 == num
  end
end
