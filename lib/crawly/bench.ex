defmodule Crawly.Bench do
  @moduledoc """
  TODO
  """

  def start_benchmark do
    Application.ensure_all_started(:crawly)
    Crawly.Engine.start_spider Crawly.Bench.BenchSpider
  end
end
