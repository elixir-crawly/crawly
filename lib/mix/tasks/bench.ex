defmodule Mix.Tasks.Bench do
  use Mix.Task

  def run([]), do: Crawly.Bench.start_benchmark()
  def run(spider_name), do: Crawly.Bench.start_benchmark(spider_name)
end
