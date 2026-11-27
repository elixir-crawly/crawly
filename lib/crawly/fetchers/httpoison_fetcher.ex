defmodule Crawly.Fetchers.HTTPoisonFetcher do
  @moduledoc """
  Implements Crawly.Fetchers.Fetcher behavior based on HTTPoison HTTP client.

  Requests get these timeouts, in milliseconds, unless the request sets its
  own, for example through `Crawly.Middlewares.RequestOptions`:

    * `:timeout` is how long to wait to connect (default `8_000`).
    * `:recv_timeout` is how long to wait for the response (default `5_000`).

  HTTPoison 3 / hackney 4 wait forever for a response by default, so without
  these a server that accepts the connection and never answers would block a
  worker indefinitely.
  """
  @behaviour Crawly.Fetchers.Fetcher

  @default_options [timeout: 8_000, recv_timeout: 5_000]

  @doc false
  def default_options, do: @default_options

  def fetch(request, _client_options) do
    # TODO: This should return Crawly.Response.
    options = Keyword.merge(@default_options, request.options || [])
    HTTPoison.get(request.url, request.headers, options)
  end
end
