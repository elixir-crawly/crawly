defmodule WorkerTest do
  use ExUnit.Case

  describe "Check that worker intervals are working correctly" do
    setup do
      :meck.expect(Crawly.RequestsStorage, :pop, fn _ -> nil end)

      spider_name = Elixir.TestWorker

      {:ok, storage_pid} = Crawly.DataStorage.start_worker(spider_name)

      {:ok, workers_sup} =
        DynamicSupervisor.start_link(strategy: :one_for_one, name: spider_name)

      {:ok, pid} =
        DynamicSupervisor.start_child(
          spider_name,
          {Crawly.Worker, [spider_name]}
        )

      on_exit(fn ->
        :meck.unload(Crawly.RequestsStorage)
        :ok = TestUtils.stop_process(workers_sup)
        :ok = TestUtils.stop_process(storage_pid)
      end)

      {:ok, %{crawler: pid, name: spider_name}}
    end

    test "Backoff increased when there is no work", context do
      send(context.crawler, :work)
      state = :sys.get_state(context.crawler)
      assert state.backoff > 300
    end

    test "Backoff interval restores if requests are in the system", context do
      :meck.expect(Crawly.RequestsStorage, :pop, fn _ ->
        Crawly.Utils.request_from_url("https://example.com")
      end)

      send(context.crawler, :work)
      state = :sys.get_state(context.crawler)
      assert state.backoff == 300
    end
  end

  describe "Check different incorrect status codes from HTTP client" do
    setup do
      :meck.expect(Crawly.Utils, :send_after, fn _, _, _ -> :ignore end)

      spider_name = Elixir.Worker.CrashingTestSpider

      {:ok, storage_pid} = Crawly.DataStorage.start_worker(spider_name)

      {:ok, workers_sup} =
        DynamicSupervisor.start_link(strategy: :one_for_one, name: spider_name)

      {:ok, pid} =
        DynamicSupervisor.start_child(
          spider_name,
          {Crawly.Worker, [spider_name]}
        )
      {:ok, requests_storage_pid} = Crawly.RequestsStorage.start_worker(
        spider_name
      )
      :ok = Crawly.RequestsStorage.store(
        spider_name,
        Crawly.Utils.request_from_url("https://www.example.com")
      )

      on_exit(fn ->
        :meck.unload()

        :ok = TestUtils.stop_process(workers_sup)
        :ok = TestUtils.stop_process(storage_pid)
        :ok = TestUtils.stop_process(requests_storage_pid)
      end)

      {:ok, %{crawler: pid, name: spider_name, requests_storage: requests_storage_pid}}
    end

    test "Pages with http 404 are handled correctly", context do
      test_pid = self()
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 404,
           body: "",
           headers: [],
           request: %{}
         }}
      end)

      # Mock the request storage, so we can see how request looks like
      :meck.expect(Crawly.RequestsStorage, :store, fn _spider_name, request ->
        send(test_pid, {:request, request})
        :ok
      end)

      # Start actual work
      send(context.crawler, :work)

      response = receive_mocked_response()
      assert response != false
      assert response.retries == 1

      assert Process.alive?(context.crawler)
    end

    test "Pages with http timeout are handled correctly", context do
      test_pid = self()
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
      end)

      # Mock the request storage, so we can see how request looks like
      :meck.expect(Crawly.RequestsStorage, :store, fn _spider_name, request ->
        send(test_pid, {:request, request})
        :ok
      end)

      send(context.crawler, :work)

      response = receive_mocked_response()
      assert response != false
      assert response.retries == 1
      assert Process.alive?(context.crawler)
    end

    test "Worker is not crashing when spider callback crashes", context do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "Some page",
           headers: [],
           request: %{}
         }}
      end)

      send(context.crawler, :work)
      assert Process.alive?(context.crawler)
    end

    test "Requests are dropped after 3 attempts", context do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok,
          %HTTPoison.Response{
            status_code: 500,
            body: "Some page",
            headers: [],
            request: %{}
          }}
      end)

      # Check if request is really dropped
      send(context.crawler, :work)
      send(context.crawler, :work)
      send(context.crawler, :work)
      send(context.crawler, :work)

      # For now I don't see a good way of understanding when the worker
      # have finished it's work. So have to do this ugly sleep
      Process.sleep(1000)

      {:stored_requests, num} =
        Crawly.DataStorage.Worker.stats(context.requests_storage)
      assert num == 0


      assert Process.alive?(context.crawler)
    end
  end

  defp receive_mocked_response() do
    # Check to see if request is added back to the request storage,
    # and if the number of retries was incremented
    receive do
      {:request, req} ->
        req
    after 1000 ->
      false
    end
  end

end

defmodule Worker.CrashingTestSpider do
  @behaviour Crawly.Spider

  @impl Crawly.Spider
  def base_url() do
    "https://www.example.com"
  end

  @impl Crawly.Spider
  def init() do
    [
      start_urls: ["https://www.example.com"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(_response) do
    {[], []}
  end
end
