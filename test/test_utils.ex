defmodule TestUtils do
  @moduledoc false
  def stop_process(pid) do
    :erlang.exit(pid, :shutdown)
    wait_pid(pid)
    :ok
  end

  def wait_pid(pid, timeout \\ 5_000) do
    :erlang.monitor(:process, pid)

    result =
      receive do
        {:DOWN, _, _, ^pid, reason} -> {:ok, reason}
      after
        timeout -> timeout
      end

    result
  end

  def assert_eventually(fun, timeout \\ 2_000, interval \\ 20) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_assert_eventually(fun, deadline, interval)
  end

  defp do_assert_eventually(fun, deadline, interval) do
    fun.()
  rescue
    error ->
      if System.monotonic_time(:millisecond) >= deadline do
        reraise error, __STACKTRACE__
      else
        Process.sleep(interval)
        do_assert_eventually(fun, deadline, interval)
      end
  end
end

defmodule TestSpider do
  @moduledoc false
  use Crawly.Spider

  def base_url() do
    "https://www.example.com"
  end

  def init() do
    [
      start_urls: ["https://www.example.com/blog.html"]
    ]
  end

  def parse_item(_response) do
    path = Enum.random(1..100)

    %Crawly.ParsedItem{
      :items => [
        %{title: "t_#{path}", url: "example.com", author: "Me", time: "not set"}
      ],
      :requests => [
        Crawly.Utils.request_from_url("https://www.example.com/#{path}")
      ]
    }
  end
end

defmodule UtilsTestSpider do
  @moduledoc false
  use Crawly.Spider

  @impl true
  def init(init_arg) do
    init_arg
  end

  @impl Crawly.Spider
  def base_url() do
    "https://www.example.com"
  end

  @impl Crawly.Spider
  def init() do
    [
      start_urls: ["https://www.example.com"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(_response) do
    {[], []}
  end
end

defmodule PipelineTestSpider do
  @moduledoc false
  use Crawly.Spider

  @impl true
  def init(init_arg) do
    init_arg
  end

  @impl Crawly.Spider
  def base_url() do
    "https://www.example.com"
  end

  @impl Crawly.Spider
  def init() do
    [
      start_urls: ["https://www.example.com"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(_response) do
    {[], []}
  end
end
