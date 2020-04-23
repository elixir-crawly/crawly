defmodule Crawly do
  @moduledoc """
  Crawly is a fast high-level web crawling & scraping framework for Elixir.
  """

  @doc """
  Fetches a given url. This function is mainly used for the spiders development
  when you need to get individual pages and parse them.

  The fetched URL is being converted to a request, and the request is piped
  through the middlewares specidied in a config (with the exception of
  `Crawly.Middlewares.DomainFilter`, `Crawly.Middlewares.RobotsTxt` these 2 are
  ignored)

  """
  @spec fetch(url, headers, options) :: HTTPoison.Response.t()
        when url: binary(),
             headers: [],
             options: []
  def fetch(url, headers \\ [], options \\ []) do
    request0 = Crawly.Request.new(url, headers, options)
    ignored_middlewares = [
      Crawly.Middlewares.DomainFilter,
      Crawly.Middlewares.RobotsTxt
    ]
    middlewares = request0.middlewares -- ignored_middlewares

    {request, _} = Crawly.Utils.pipe(middlewares, request0, %{})

    {fetcher, client_options} = Application.get_env(
      :crawly,
      :fetcher,
      {Crawly.Fetchers.HTTPoisonFetcher, []}
    )

    {:ok, response} = fetcher.fetch(request, client_options)
    response
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


  def list_spiders() do
    Enum.reduce(
      get_modules_from_applications(),
      [],
      fn mod, acc ->
        try do
          beh = Keyword.get(mod.__info__(:attributes), :behaviour)

          case beh == [Crawly.Spider] do
            true ->
              [mod] ++ acc
            false ->
              acc
          end

        rescue _ -> acc end
      end)
  end

  def get_modules_from_applications do
    Enum.reduce(Application.started_applications(), [], fn {app, _descr, _vsn}, acc ->
      case :application.get_key(app, :modules) do
        {:ok, modules} ->
          modules ++ acc
        other ->
          acc
      end
     end)
  end
end
