defmodule UtilsTest do
  use ExUnit.Case

  setup do
    on_exit(fn -> :meck.unload() end)

    :ok
  end

  test "Request from url" do
    requests = Crawly.Utils.request_from_url("https://test.com")
    assert requests == expected_request("https://test.com")
  end

  test "Requests from urls" do
    requests =
      Crawly.Utils.requests_from_urls([
        "https://test.com",
        "https://example.com"
      ])

    assert requests == [
             expected_request("https://test.com"),
             expected_request("https://example.com")
           ]
  end

  test "Build absolute url test" do
    url = Crawly.Utils.build_absolute_url("/url1", "http://example.com")
    assert url == "http://example.com/url1"
  end

  test "Build absolute urls test" do
    paths = ["/path1", "/path2"]
    result = Crawly.Utils.build_absolute_urls(paths, "http://example.com")

    assert result == ["http://example.com/path1", "http://example.com/path2"]
  end

  test "pipe with args" do
    # make mock pipeline
    :meck.new(FakePipeline, [:non_strict])

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state, args ->
        {item, Map.put(state, :args, args)}
      end
    )

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state ->
        {item, state}
      end
    )

    {_item, state} =
      Crawly.Utils.pipe([{FakePipeline, my: "arg"}], %{my: "item"}, %{})

    assert state.args == [my: "arg"]
  end

  test "pipe without args" do
    # make mock pipeline
    :meck.new(FakePipeline, [:non_strict])

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state, args ->
        {item, %{state | args: args}}
      end
    )

    :meck.expect(
      FakePipeline,
      :run,
      fn item, state ->
        {item, state}
      end
    )

    {_item, state} = Crawly.Utils.pipe([FakePipeline], %{my: "item"}, %{})

    assert Map.has_key?(state, :args) == false
  end

  test "can find CrawlySpider behaviors" do
    assert Enum.any?(
             Crawly.Utils.list_spiders(),
             fn x -> x == UtilsTestSpider end
           )
  end

  defp expected_request(url) do
    %Crawly.Request{
      url: url,
      headers: [],
      options: [],
      middlewares: [
        Crawly.Middlewares.DomainFilter,
        Crawly.Middlewares.UniqueRequest,
        Crawly.Middlewares.RobotsTxt,
        {Crawly.Middlewares.UserAgent, user_agents: ["My Custom Bot"]}
      ],
      retries: 0
    }
  end
end
