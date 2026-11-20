defmodule LocalBooks do
  @moduledoc """
  Runs `LocalBooks.BooksSpider` against the local books site.
  """

  alias LocalBooks.BooksSpider

  @doc """
  Starts the spider and waits until Crawly stops it, or until `:timeout`
  milliseconds have passed, in which case the spider is stopped (hard kill).

  Options are passed to `Crawly.Engine.start_spider/2`, except:

    * `:timeout` - how long to wait before killing the spider
      (default 120_000 ms)

  Returns:

    * `:crawl_id` - id of the crawl, also part of the items file name
    * `:stopped` - `:finished` if Crawly stopped on its own, `:killed` if
      the timeout hit
    * `:elapsed_ms` - how long the crawl ran
    * `:items_file` - the `.jl` file written by the `WriteToFile` pipeline
  """
  @spec crawl(keyword()) :: map()
  def crawl(opts \\ []) do
    {timeout, opts} = Keyword.pop(opts, :timeout, 120_000)

    started_at = System.monotonic_time(:millisecond)
    :ok = Crawly.Engine.start_spider(BooksSpider, opts)
    {:ok, crawl_id} = Crawly.Engine.get_crawl_id(BooksSpider)

    stopped =
      case wait_until_stopped(started_at + timeout) do
        :finished ->
          :finished

        :timeout ->
          Crawly.Engine.stop_spider(BooksSpider, :killed_by_timeout)
          :killed
      end

    %{
      crawl_id: crawl_id,
      stopped: stopped,
      elapsed_ms: System.monotonic_time(:millisecond) - started_at,
      items_file: items_file(crawl_id)
    }
  end

  defp wait_until_stopped(deadline) do
    cond do
      not Map.has_key?(Crawly.Engine.running_spiders(), BooksSpider) ->
        :finished

      System.monotonic_time(:millisecond) >= deadline ->
        :timeout

      true ->
        Process.sleep(200)
        wait_until_stopped(deadline)
    end
  end

  # WriteToFile names files "<Spider>_<timestamp>_<crawl_id>.jl"
  defp items_file(crawl_id) do
    folder =
      :crawly
      |> Application.get_env(:pipelines, [])
      |> Enum.find_value("./", fn
        {Crawly.Pipelines.WriteToFile, opts} -> Keyword.get(opts, :folder)
        _ -> nil
      end)

    case Path.wildcard(Path.join(folder, "*_#{crawl_id}.jl")) do
      [file] -> file
      [] -> nil
    end
  end
end
