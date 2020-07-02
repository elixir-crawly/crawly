defmodule BenchTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Features.Manager.TestSpider

  test "running mix bench" do
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
    Application.put_env(:crawly, :closespider_itemcount, 1)

    assert capture_log(fn -> Mix.Tasks.Bench.run([]) end) =~
             " | Number of reductions since the last time: "
  end

  test "running mix bench on testSpider" do
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
    Application.put_env(:crawly, :closespider_itemcount, 1)

    :meck.expect(HTTPoison, :get, fn _, _, _ ->
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: "Some page",
         headers: [],
         request: %{}
       }}
    end)

    assert capture_log(fn -> Mix.Tasks.Bench.run(TestSpider) end) =~
             " | Number of reductions since the last time: "

    :meck.unload()
    Crawly.Engine.stop_spider(TestSpider)
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
    Application.put_env(:crawly, :closespider_timeout, 20)
    Application.put_env(:crawly, :closespider_itemcount, 1)
  end
end
