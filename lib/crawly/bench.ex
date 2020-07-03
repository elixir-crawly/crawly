defmodule Crawly.Bench do
  @moduledoc """
  This module implements a simple benchmarking suite that spawns a local HTTP
  server to exercise Crawly to the maximum possible speed
  """
  require Logger

  alias Crawly.Engine

  @spider_name Crawly.Bench.BenchSpider

  @spec start_benchmark(atom) :: nil
  def start_benchmark(spider_name) do
    {:ok, _} = Application.ensure_all_started(:crawly)
    :ok = Application.put_env(:crawly, :bench, true, persistent: true)
    Crawly.Engine.start_spider(spider_name)
    wait_until(spider_name, {0, 0, 0})
  end

  @spec start_benchmark :: nil
  def start_benchmark, do: start_benchmark(@spider_name)

  defp wait_until(name, reduc_num_of_items, retries \\ 200, interval \\ 1000)

  defp wait_until(spider_name, {_, _, items}, 0, _) do
    Logger.info("Stopping #{inspect(spider_name)}")
    Engine.stop_spider(spider_name, :normal)
    Logger.info("Max of #{items} requests/sec")
  end

  defp wait_until(name, {reduc, num_of_items, max_items}, retries, interval) do
    Process.sleep(interval)

    if Process.whereis(name) do
      spiders = Engine.running_spiders()

      {_, pid, :worker, _} =
        Supervisor.which_children(Map.get(spiders, name))
        |> Enum.find(&({Crawly.Manager, _, :worker, [Crawly.Manager]} = &1))

      {:info, info, :items_count, items_count} =
        GenServer.call(pid, :collect_metrics)

      reductions = Keyword.get(info, :reductions)
      total_heap_size = Keyword.get(info, :total_heap_size)
      heap_size = Keyword.get(info, :heap_size)
      mem = total_heap_size - heap_size
      items = items_count - num_of_items

      Logger.info(
        "Mem usage: #{mem} | Number of reductions since the last time: #{
          reductions - reduc
        } | Current crawl speed is: #{items} requests/sec"
      )

      wait_until(
        name,
        {reduc, items_count, max(items, max_items)},
        retries - 1,
        interval
      )
    end
  end
end
