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
    HTTPoison.get(url, headers, options)
  end

end
