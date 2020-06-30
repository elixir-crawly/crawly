defmodule Mix.Tasks.Bench do
  use Mix.Task

  def run(_), do: Crawly.Bench.start_benchmark()
end
