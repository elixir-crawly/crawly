defmodule Crawly.E2E.BooksCrawlTest do
  @moduledoc """
  End-to-end test: runs a real spider (`Crawly.E2E.BooksSpider`) through the
  whole engine (manager, workers, middlewares, pipelines, `WriteToFile`)
  against a local copy of books.toscrape.com, then checks what was crawled
  and stored.

  Excluded from a plain `mix test`. Start the site, then run it:

      docker compose -f test/e2e/docker-compose.yml up -d --build --wait
      mix test --only e2e

  A crawl takes about 75 s and prints its progress.

  Environment:

    * `CRAWLY_E2E_BASE_URL` - site to crawl (default `http://localhost:8080`)
    * `CRAWLY_E2E_TIMEOUT_MS` - the crawl must stop on its own within this
      time, or it is killed and the test fails (default 120000)
  """
  use Crawly.TestCase, async: false

  alias Crawly.E2E.BooksSpider

  @moduletag :e2e
  @moduletag timeout: 300_000

  @spider BooksSpider

  # The local copy has 9 catalogue pages with 20 books each. Page 9's "next"
  # link points at the real books.toscrape.com and must be dropped by
  # SameDomainFilter.
  @pages ["/index.html"] ++ Enum.map(2..9, &"/catalogue/page-#{&1}.html")

  # Every book on those pages, extracted from the HTML independently of the
  # spider (see test/e2e/site/README.md).
  @expected_books_file Path.expand("site/expected_books.json", __DIR__)
  @external_resource @expected_books_file

  setup_all do
    base_url = BooksSpider.base_url()
    ensure_site_up!(base_url)

    timeout =
      String.to_integer(System.get_env("CRAWLY_E2E_TIMEOUT_MS", "120000"))

    crawl = crawl!(timeout)

    # Printed after all tests in this module have run.
    on_exit(fn -> IO.puts(report(crawl, base_url, timeout)) end)

    %{base_url: base_url, crawl: crawl, timeout: timeout}
  end

  test "the spider stops on its own within the time limit", %{
    crawl: crawl,
    timeout: timeout
  } do
    assert crawl.stopped == {:closed, :spider_finished},
           "expected the spider to finish by itself within #{timeout} ms, " <>
             "got #{inspect(crawl.stopped)} after #{crawl.elapsed_ms} ms"
  end

  test "visits exactly the 9 local catalogue pages, once each", %{
    crawl: crawl,
    base_url: base_url
  } do
    visited = Enum.map(crawl.pages, fn {url, _status, _items} -> url end)

    assert Enum.sort(visited) == Enum.sort(Enum.map(@pages, &(base_url <> &1)))

    for {url, status, items} <- crawl.pages do
      assert status == 200, "#{url} returned #{status}"
      assert items == 20, "#{url} gave #{items} items"
    end
  end

  test "stores exactly the books on the site", %{
    crawl: crawl,
    base_url: base_url
  } do
    expected =
      @expected_books_file
      |> File.read!()
      |> Poison.decode!()
      |> Enum.map(
        &%{
          "url" => base_url <> &1["path"],
          "title" => &1["title"],
          "price" => &1["price"]
        }
      )

    actual = crawl.items

    missing = expected -- actual
    unexpected = actual -- expected

    assert missing == [] and unexpected == [],
           "#{length(missing)} books missing, #{length(unexpected)} unexpected\n" <>
             "missing (first 5): #{inspect(Enum.take(missing, 5))}\n" <>
             "unexpected (first 5): #{inspect(Enum.take(unexpected, 5))}"

    assert length(actual) == length(expected),
           "some books were stored more than once"
  end

  test "writes one JSON object per line with only the scraped fields", %{
    crawl: crawl
  } do
    for item <- crawl.items do
      assert item |> Map.keys() |> Enum.sort() == ["price", "title", "url"]
    end
  end

  test "records the crawl as a finished job", %{crawl: crawl} do
    assert {:ok, %Crawly.Models.Job{} = job} = crawl.job
    assert job.spider_name == inspect(@spider)
    assert job.scraped_items == length(crawl.items)
    assert job.stop_reason == :spider_finished
    assert job.end != nil
  end

  ## Crawl

  # Runs the spider until it stops on its own, or kills it at `timeout`.
  # Everything the tests need is collected here, because Crawly.TestCase
  # resets global state (including stored jobs) before each test.
  defp crawl!(timeout) do
    reset_global_state()

    output_dir =
      Path.join(
        System.tmp_dir!(),
        "crawly_e2e_#{System.unique_integer([:positive])}"
      )

    Application.put_env(:crawly, :e2e_output_dir, output_dir)
    Application.put_env(:crawly, :e2e_test_pid, self())

    try do
      # Crawly reads spider settings only from loaded modules.
      Code.ensure_loaded!(@spider)

      started_at = System.monotonic_time(:millisecond)
      :ok = Crawly.Engine.start_spider(@spider)
      {:ok, crawl_id} = Crawly.Engine.get_crawl_id(@spider)

      {stopped, pages, page_times} =
        await(crawl_id, started_at, started_at + timeout, [], [])

      elapsed_ms = System.monotonic_time(:millisecond) - started_at

      if stopped == :killed,
        do: Crawly.Engine.stop_spider(@spider, :killed_by_test)

      wait_until_stopped()

      items_file = Path.join(output_dir, "#{inspect(@spider)}_#{crawl_id}.jl")
      items = read_items(items_file)

      %{
        crawl_id: crawl_id,
        stopped: stopped,
        elapsed_ms: elapsed_ms,
        pages: pages,
        page_times: page_times,
        items: items,
        items_file_bytes: File.stat!(items_file).size,
        job: Crawly.Models.Job.get(crawl_id)
      }
    after
      Enum.each(
        [:e2e_output_dir, :e2e_test_pid],
        &Application.delete_env(:crawly, &1)
      )

      File.rm_rf!(output_dir)
    end
  end

  # Collects page notifications (printing progress) until the spider closes
  # or the deadline passes. Returns pages and the time (ms since start) each
  # one was parsed, in arrival order.
  defp await(crawl_id, started_at, deadline, pages, times) do
    wait = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:e2e_page, url, status, items} ->
        at = System.monotonic_time(:millisecond) - started_at

        IO.puts(
          "[e2e] #{secs(at)}s page #{length(pages) + 1}: #{status} #{url} (#{items} items)"
        )

        await(
          crawl_id,
          started_at,
          deadline,
          pages ++ [{url, status, items}],
          times ++ [at]
        )

      {:e2e_spider_closed, ^crawl_id, reason} ->
        {{:closed, reason}, pages, times}
    after
      wait -> {:killed, pages, times}
    end
  end

  defp wait_until_stopped(attempts \\ 50) do
    if Map.has_key?(Crawly.Engine.running_spiders(), @spider) and attempts > 0 do
      Process.sleep(100)
      wait_until_stopped(attempts - 1)
    end
  end

  # WriteToFile uses delayed writes, and the file is closed asynchronously
  # when the spider stops, so wait for its content to settle.
  defp read_items(file, previous \\ nil, attempts \\ 50) do
    content = if File.exists?(file), do: File.read!(file)

    cond do
      content != nil and content == previous ->
        content |> String.split("\n", trim: true) |> Enum.map(&Poison.decode!/1)

      attempts == 0 ->
        flunk("items file #{file} was never written")

      true ->
        Process.sleep(100)
        read_items(file, content, attempts - 1)
    end
  end

  ## Report

  defp report(crawl, base_url, timeout) do
    %{items: items, pages: pages, page_times: times} = crawl
    last_page_at = List.last(times) || 0

    gaps =
      times
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> b - a end)

    prices = Enum.map(items, &price/1)
    titles = Enum.map(items, & &1["title"])
    path = &String.replace_prefix(&1, base_url, "")

    stopped =
      case crawl.stopped do
        {:closed, reason} ->
          "#{reason} (stopped by itself)"

        :killed ->
          "KILLED after #{secs(crawl.elapsed_ms)} s (limit #{secs(timeout)} s)"
      end

    statuses =
      pages
      |> Enum.frequencies_by(fn {_, status, _} -> status end)
      |> Enum.map_join(", ", fn {status, n} -> "#{n} x #{status}" end)

    job =
      case crawl.job do
        {:ok, job} ->
          "#{job.scraped_items} items, stop reason #{inspect(job.stop_reason)}"

        other ->
          inspect(other)
      end

    page_rows =
      pages
      |> Enum.zip(times)
      |> Enum.map_join("\n", fn {{url, status, n}, at} ->
        "  #{pad(secs(at), 7)}  #{pad(status, 6)}  #{pad(n, 5)}  #{path.(url)}"
      end)

    samples =
      [
        List.first(items),
        Enum.at(items, div(length(items), 2)),
        List.last(items)
      ] ++
        [Enum.max_by(items, &String.length(&1["title"]), fn -> nil end)]

    sample_rows =
      samples
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.map_join("\n", fn item ->
        "  #{String.pad_trailing(item["price"], 8)}  #{path.(item["url"])}  #{item["title"]}"
      end)

    """

    ======================== e2e crawl report ========================
    Spider:        #{inspect(@spider)}  (crawl #{crawl.crawl_id})
    Site:          #{base_url}
    Stopped:       #{stopped}
    Duration:      #{secs(crawl.elapsed_ms)} s total, last page parsed at #{secs(last_page_at)} s,
                   #{secs(crawl.elapsed_ms - last_page_at)} s waiting for Crawly to notice it was done
    Pages:         #{length(pages)} fetched (#{statuses})
    Page gaps:     #{gap_stats(gaps)}
    Throughput:    #{rate(length(pages), crawl.elapsed_ms, 60_000)} pages/min, #{rate(length(items), crawl.elapsed_ms, 1000)} items/s (whole crawl)
    Items:         #{length(items)} stored, #{length(Enum.uniq(titles))} unique titles, items file #{Float.round(crawl.items_file_bytes / 1024, 1)} KB
    Prices:        #{price_stats(prices)}
    Job record:    #{job}

    Pages (time of parse, status, items, path):
    #{page_rows}

    Sample items (first, middle, last, longest title):
    #{sample_rows}
    ==================================================================
    """
  end

  defp gap_stats([]), do: "n/a"

  defp gap_stats(gaps),
    do:
      "min #{secs(Enum.min(gaps))} s, avg #{secs(div(Enum.sum(gaps), length(gaps)))} s, " <>
        "max #{secs(Enum.max(gaps))} s"

  defp price_stats([]), do: "n/a"

  defp price_stats(prices) do
    avg = Enum.sum(prices) / length(prices)

    "min £#{money(Enum.min(prices))}, max £#{money(Enum.max(prices))}, avg £#{money(avg)}"
  end

  defp price(item) do
    case Float.parse(String.replace(item["price"], "£", "")) do
      {value, _} -> value
      :error -> 0.0
    end
  end

  defp money(value), do: :erlang.float_to_binary(value * 1.0, decimals: 2)
  defp rate(_n, 0, _per), do: "n/a"
  defp rate(n, ms, per), do: Float.round(n * per / ms, 1)
  defp secs(ms), do: Float.round(ms / 1000, 1)
  defp pad(value, width), do: String.pad_leading(to_string(value), width)

  defp ensure_site_up!(base_url) do
    case Crawly.fetch(base_url <> "/index.html") do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        :ok

      other ->
        raise """
        The e2e site is not reachable at #{base_url} (#{inspect(other)}).
        Start it with:

            docker compose -f test/e2e/docker-compose.yml up -d --build --wait
        """
    end
  end
end
