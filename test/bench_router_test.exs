defmodule BenchRouterTest do
  use ExUnit.Case, async: false

  alias Crawly.Bench.BenchRouter

  test "it spawns a local HTTP server" do
    Application.put_env(:crawly, :closespider_timeout, 10, persistent: true)

    Application.put_env(:crawly, :manager_operations_timeout, 10,
      persistent: true
    )

    Crawly.Bench.start_benchmark(TestSpider)
    assert Application.get_env(:crawly, :bench)
    assert {:ok, _} = BenchRouter.build_url() |> HTTPoison.get()
    Crawly.Engine.stop_spider(TestSpider)
  end
end
