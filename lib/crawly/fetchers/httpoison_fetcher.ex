defmodule Crawly.Fetchers.HTTPoisonFetcher do
  @moduledoc """
  Implements Crawly.Fetchers.Fetcher behavior based on HTTPoison HTTP client
  """
  @behaviour Crawly.Fetchers.Fetcher

  require Logger

  def fetch(request) do
    HTTPoison.get(request.url, request.headers, request.options)
  end
end
