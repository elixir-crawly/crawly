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
  def fetch(url, headers \\ [], request_options \\ []) do
    # Try to use options provided by a fetch function. If nothing is provided
    # then use options provided by a config.
    options =
      case request_options do
        [] ->
          Application.get_env(:crawly, :httpoison_options, [])
        _ ->
          request_options
      end


    HTTPoison.get(url, headers, options)
  end
end
