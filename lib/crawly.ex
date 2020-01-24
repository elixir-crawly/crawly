defmodule Crawly do
  @moduledoc """
  Crawly is a fast high-level web crawling & scraping framework for Elixir.
  """

  @doc """
  Fetches a given url. This function is mainly used for the spiders development
  when you need to get individual pages and parse them
  """
  @spec fetch(url, headers, options) :: HTTPoison.Response.t()
        when url: binary(),
             headers: [],
             options: []
  def fetch(url, headers \\ [], options \\ []) do
    options = [follow_redirect: Application.get_env(:crawly, :follow_redirect, false)] ++ options

    options =
      case Application.get_env(:crawly, :proxy, false) do
        false ->
          options

        proxy ->
          options ++ [{:proxy, proxy}]
      end
    request = Crawly.Request.new(url, headers, options)


    {fetcher, client_options} = Application.get_env(
      :crawly,
      :fetcher,
      {Crawly.Fetchers.HTTPoisonFetcher, []}
    )

    fetcher.fetch(request, client_options)

  end
end
