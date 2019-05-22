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
      :meck.expect(Crawly.RequestsStorage, :pop, fn _ ->
        Crawly.Utils.request_from_url("https://example.com")
      end)

      spider_name = Worker.CrashingTestSpider

      :meck.new(spider_name, [:non_strict])

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
        :meck.unload(HTTPoison)

        :ok = TestUtils.stop_process(workers_sup)
        :ok = TestUtils.stop_process(storage_pid)
      end)

      {:ok, %{crawler: pid, name: spider_name}}
    end

    test "Pages with http 500 are handled correctly", context do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 500,
           body: "",
           headers: [],
           request: %{}
         }}
      end)

      send(context.crawler, :work)
      Process.sleep(1_000)

      assert Process.alive?(context.crawler)
    end

    test "Pages with http 404 are handled correctly", context do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 404,
           body: "",
           headers: [],
           request: %{}
         }}
      end)

      # send(context.crawler, :work)
      Process.sleep(1_000)
      assert Process.alive?(context.crawler)
    end

    test "Pages with http timeout are handled correctly", context do
      :meck.expect(HTTPoison, :get, fn _, _, _ ->
        {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
      end)

      send(context.crawler, :work)
      Process.sleep(1_000)
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

      Process.sleep(1_000)
      assert Process.alive?(context.crawler)
    end
  end

end

defmodule Worker.CrashingTestSpider do
  def parse_item(_response) do
    {:error, :error}
  end
end
