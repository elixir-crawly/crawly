defmodule SettingsTest do
  use ExUnit.Case

  setup do
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
             Crawly.Utils.get_settings(
               :concurrent_requests_per_domain,
               TestSpiderSettingsOverride,
               1
             )
  end

  test "incomplete spider overrides do not break global settings" do
    assert 10 ==
             Crawly.Utils.get_settings(
               :closespider_itemcount,
               TestSpiderSettingsOverride,
               1
             )
  end
end

defmodule Elixir.TestSpiderSettingsOverride do
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
    %{:items => [], :requests => []}
  end

  def override_settings(), do: [concurrent_requests_per_domain: 5]
end
