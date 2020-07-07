defmodule BenchTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  test "it can load bench_spider and log metrics" do
    Application.put_env(:crawly, :manager_operations_timeout, 10,
      persistent: true
    )

    spider_name = Crawly.Bench.BenchSpider
    assert Code.ensure_loaded?(spider_name)

    assert capture_log(fn -> Crawly.Bench.start_benchmark() end) =~
             "Current crawl speed is: "
  end
end
