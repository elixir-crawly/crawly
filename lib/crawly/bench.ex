defmodule Crawly.Bench do
  @moduledoc """
  TODO
  """
  require Logger

  alias Crawly.Manager

  def start_benchmark do
    {:ok, _} = Application.ensure_all_started(:crawly)
    :ok = Application.put_env(:crawly, :bench, true, persistent: true)
    spider_name = Crawly.Bench.BenchSpider
    Crawly.Engine.start_spider(spider_name)
    wait_until(spider_name, 0)
  end

  defp wait_until(name, reduc, retries \\ 200, interval \\ 5000)

  defp wait_until(_, _, 0, _), do: raise("The spider doesn't stop")

  defp wait_until(name, reduc, retries, interval) do
    Process.sleep(interval)

    if Process.whereis(name) do
      {:info, info, :delta, delta} = Manager.collect_metrics(name)
      reductions = Keyword.get(info, :reductions)
      total_heap_size = Keyword.get(info, :total_heap_size)
      heap_size = Keyword.get(info, :heap_size)
      mem = total_heap_size - heap_size

      Logger.info(
        "Mem usage: #{mem} | Number of reductions since the last time: #{
          reductions - reduc
        } | Current crawl speed is: #{delta} items/min"
      )

      wait_until(name, reductions, retries - 1, interval)
    end
  end
end
