defmodule Features.Manager.TestSpider do
  use Crawly.Spider

  def override_settings() do
    on_spider_closed_callback = fn reason ->
      case Process.whereis(:spider_closed_callback_test) do
        nil ->
          :nothing_to_do

        _pid ->
          send(:spider_closed_callback_test, reason)
      end
    end

    [on_spider_closed_callback: on_spider_closed_callback]
  end

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

    %{
      :items => [
        %{title: "t_#{path}", url: "example.com", author: "Me", time: "not set"}
      ],
      :requests => [
        Crawly.Utils.request_from_url("https://www.example.com/#{path}")
      ]
    }
  end

  def spider_closed(:manual_stop) do
    send(:spider_closed_callback_test, :manual_stop)
  end

  def spider_closed(_) do
    :ignored
  end
end
