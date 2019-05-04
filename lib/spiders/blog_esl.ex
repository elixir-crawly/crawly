defmodule BlogEsl do
  def base_url() do
    # "https://www.erlang-solutions.com/"
    "meta.ua"
  end

  def init() do
    [
      # start_urls: ["https://www.erlang-solutions.com/blog.html"]
      start_urls: ["https://www.meta.ua"]
    ]
  end

  def parse_item(response) do
    urls =
      response.body
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.uniq()

    requests =
      Enum.map(urls, fn url ->
        url
        |> build_absolute_url(response.request_url)
        |> Crawly.Utils.request_from_url()
      end)

    %{:requests => requests, :items => []}
  end

  def build_absolute_url(url, request_url) do
    URI.merge(request_url, url) |> to_string()
  end
end
