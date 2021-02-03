defmodule RequestStorageTest do
  use ExUnit.Case, async: false

  @name "my_test_spider"
  @other_name "my_dead_test_spider"
  @crawl_id "crawl_id"
  setup do
    {:ok, pid} = Crawly.RequestsStorage.start_worker(@name, @crawl_id)

    on_exit(fn ->
      req_storage_pid = Process.whereis(Crawly.RequestsStorage)
      state = :sys.get_state(req_storage_pid)

      for {_, worker_pid} <- state.workers do
        DynamicSupervisor.terminate_child(
          Crawly.RequestsStorage.WorkersSup,
          worker_pid
        )
      end
    end)

    {:ok, pid: pid}
  end

  test "Request storage can store requests" do
    request = %Crawly.Request{url: "http://example.com"}
    :ok = Crawly.RequestsStorage.store(@name, request)
    {:stored_requests, num} = Crawly.RequestsStorage.stats(@name)
    assert 1 == num
  end

  test "Request storage returns request for given spider" do
    request = %Crawly.Request{url: "http://example.com"}
    :ok = Crawly.RequestsStorage.store(@name, request)
    assert request.url == Crawly.RequestsStorage.pop(@name).url
  end

  test "Returns nil if there are no requests in storage" do
    assert nil == Crawly.RequestsStorage.pop(@name)
  end

  test "Errors for unknown spiders for request storage" do
    assert {:error, :storage_worker_not_running} ==
             Crawly.RequestsStorage.pop(@other_name)

    assert {:error, :storage_worker_not_running} ==
             Crawly.RequestsStorage.stats(@other_name)

    assert {:error, :storage_worker_not_running} ==
             Crawly.RequestsStorage.store(
               @other_name,
               Crawly.Utils.request_from_url("http://example.com")
             )
  end

  test "Stopped workers are removed from request storage state" do
    {:ok, pid} =
      Crawly.RequestsStorage.start_worker(@other_name, "diff_crawl_id")

    req_storage_pid = Process.whereis(Crawly.RequestsStorage)
    state = :sys.get_state(req_storage_pid)
    assert Enum.count(state.pid_spiders) == 2
    assert Enum.count(state.workers) == 2

    TestUtils.stop_process(pid)

    state = :sys.get_state(req_storage_pid)
    assert Enum.count(state.pid_spiders) == 1
    assert Enum.count(state.workers) == 1
  end
end
