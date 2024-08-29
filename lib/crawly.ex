defmodule Crawly do
  @moduledoc """
  Crawly is a fast high-level web crawling & scraping framework for Elixir.
  """

  require Logger

  @doc """
  Fetches the content from a given URL using the specified options.

  ## Parameters

    - `url`: The URL to fetch the content from. It should be a valid string.
    - `opts`: A keyword list of options to customize the request. The supported options are:
      - `:headers` (optional): A list of HTTP headers to include in the request. Defaults to an empty list `[]`.
      - `:request_opts` (optional): A list of options to pass to the HTTP client for configuring the request. Defaults to an empty list `[]`.
      - `:fetcher` (optional): The module responsible for performing the HTTP request. This module must implement a `fetch/2` function. Defaults to `Crawly.Fetchers.HTTPoisonFetcher`.

  ## Returns

    - `{:ok, %HTTPoison.Response{}}`: On successful fetch, returns a tuple containing `:ok` and the HTTP response.
    - `{:error, %HTTPoison.Error{}}`: On failure, returns a tuple containing `:error` and the error details.

  ## Examples

    Fetch a URL with default options:

        iex> fetch("https://example.com")
        {:ok, %HTTPoison.Response{status_code: 200, body: "...", ...}}

    Fetch a URL with custom headers:

        iex> fetch("https://example.com", headers: [{"User-Agent", "MyCrawler"}])
        {:ok, %HTTPoison.Response{status_code: 200, body: "...", ...}}

    Handle a fetch error:

        iex> fetch("https://invalid-url.com")
        {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}

  ## Notes

    - The `fetcher` option allows you to customize how the HTTP request is performed. By default, the `Crawly.Fetchers.HTTPoisonFetcher` module is used, which relies on `HTTPoison` to perform the request.
    - The `request_opts` parameter allows you to customize the behavior of the HTTP client, such as timeouts, SSL options, etc.
    - The function returns either `{:ok, response}` for successful requests or `{:error, error}` for failed requests, allowing you to handle these cases explicitly in your code.
  """
  @spec fetch(url :: String.t(), options :: list()) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def fetch(url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    request_opts = Keyword.get(opts, :request_opts, [])
    fetcher = Keyword.get(opts, :fetcher, Crawly.Fetchers.HTTPoisonFetcher)
    request = Crawly.Request.new(url, headers, request_opts)
    fetcher.fetch(request, request_opts)
  end

  @doc """
  Fetches content from the given URL and processes it with the specified spider.

  ## Parameters

    - `url`: The URL to fetch the content from. It should be a valid string.
    - `spider_name`: The spider module responsible for processing the fetched response. The module must implement a `parse_item/1` function.
    - `options`: A keyword list of options to customize the request. The options are passed directly to the `fetch/2` function.

  Returned Crawly.ParsedItem or HTTPoison error
  """
  @spec fetch_with_spider(
          url :: String.t(),
          spider_name :: module(),
          options :: list()
        ) ::
          Crawly.ParsedItem.t() | {:error, HTTPoison.Error.t()}
  def fetch_with_spider(url, spider_name, options \\ []) do
    case fetch(url, options) do
      {:ok, response} -> spider_name.parse_item(response)
      {:error, _reason} = err -> err
    end
  end

  @doc """
  Parses a given response with a given spider. Allows to quickly see the outcome
  of the given :parse_item implementation.
  """
  @spec parse(response, spider) :: {:ok, result}
        when response: Crawly.Response.t(),
             spider: atom(),
             result: Crawly.ParsedItem.t()
  def parse(response, spider) do
    case Kernel.function_exported?(spider, :parse_item, 1) do
      false ->
        {:error, :spider_not_found}

      true ->
        spider.parse_item(response)
    end
  end

  @doc """
  Returns a list of known modules which implements Crawly.Spider behaviour.

  Should not be used for spider management. Use functions defined in `Crawly.Engine` for that.
  """
  @spec list_spiders() :: [module()]
  def list_spiders(), do: Crawly.Utils.list_spiders()

  @doc """
  Loads spiders from a given directory and the simple storage
  """
  @spec load_spiders() :: :ok
  def load_spiders() do
    try do
      Crawly.Utils.load_spiders()
      Crawly.Models.YMLSpider.load()
    rescue
      error ->
        Logger.info("No spiders found to auto-load: #{inspect(error)}")
    end
  end
end
