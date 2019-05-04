defmodule BlogEsl do
  def base_url() do
     "https://www.erlang-solutions.com/"
  end

  def init() do
    [
      start_urls: ["https://www.erlang-solutions.com/blog.html"]
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
        |> build_absolute_url()
        |> Crawly.Utils.request_from_url()
      end)

    %{:requests => requests, :items => []}
  end

  def build_absolute_url(url) do
    URI.merge(base_url(), url) |> to_string()
  end
end
