defmodule UtilsTest do
  use ExUnit.Case
  alias Crawly.Utils

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
    assert Enum.any?(Utils.list_spiders(), &(&1 == TestSpider))
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

  describe "override settings" do
    setup do
      :meck.expect(TestSpider, :override_settings, fn ->
        [concurrent_requests_per_domain: 5]
      end)

      Application.ensure_all_started(Crawly)
      Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
      Application.put_env(:crawly, :closespider_itemcount, 10)

      on_exit(fn ->
        Application.put_env(:crawly, :closespider_timeout, 20)
        Application.put_env(:crawly, :closespider_itemcount, 100)
      end)
    end

    test "settings from the spider are overriding globals" do
      assert 5 ==
               Utils.get_settings(:concurrent_requests_per_domain, TestSpider)
    end

    test "incomplete spider overrides do not break global settings" do
      assert 10 == Utils.get_settings(:closespider_itemcount, TestSpider)
    end

    test "if no spider-level settings or global settings, returns default " do
      assert 1 == Utils.get_settings(:my_custom_setting, TestSpider, 1)
    end

    test "correct settings returned for runtime spider" do
      :meck.expect(Crawly.Engine, :get_spider_info, fn _ ->
        %{template: TestSpider}
      end)

      assert 2 == Utils.get_settings(:my_custom_setting, "TestSpider", 2)
    end

    test "returns :error tuple if runtime spider is not running, even if default is given" do
      :meck.expect(Crawly.Engine, :get_spider_info, fn _ ->
        nil
      end)

      assert {:error, :spider_not_found} ==
               Utils.get_settings(:my_custom_setting, "TestSpider", 1)
    end
  end
end
