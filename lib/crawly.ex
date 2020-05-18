defmodule Crawly do
  @moduledoc """
  Crawly is a fast high-level web crawling & scraping framework for Elixir.
  """

  @doc """
  Fetches a given url. This function is mainly used for the spiders development
  when you need to get individual pages and parse them.

  The fetched URL is being converted to a request, and the request is piped
  through the middlewares specidied in a config (with the exception of
  `Crawly.Middlewares.DomainFilter`, `Crawly.Middlewares.RobotsTxt`)

  Provide a spider with the `:with` option to fetch a given webpage using that spider.


  """

  @spec fetch(url, opts) :: HTTPoison.Response.t()
        when url: binary(),
             opts: list()
  def fetch(url, opts \\ []) do
    opts = Enum.into(opts, %{with: nil, request_options: [], headers: []})

    request0 =
      Crawly.Request.new(url, opts[:headers], opts[:request_options])
      |> Map.put(
        :middlewares,
        Crawly.Utils.get_settings(:middlewares, opts[:with], [])
      )

    ignored_middlewares = [
      Crawly.Middlewares.DomainFilter,
      Crawly.Middlewares.RobotsTxt
    ]

    new_middlewares = request0.middlewares -- ignored_middlewares

    request0 =
      Map.put(
        request0,
        :middlewares,
        new_middlewares
      )

    {%{} = request, _} = Crawly.Utils.pipe(request0.middlewares, request0, %{})

    {fetcher, client_options} =
      Crawly.Utils.get_settings(
        :fetcher,
        opts[:with],
        {Crawly.Fetchers.HTTPoisonFetcher, []}
      )

    {:ok, response} = fetcher.fetch(request, client_options)

    case opts[:with] do
      nil ->
        # no spider provided, return response as is
        response

      _ ->
        # spider provided, send response through  parse_item callback, pipe through the pipelines
        with parsed_result <- parse(response, opts[:with]),
             pipelines <-
               Crawly.Utils.get_settings(
                 :pipelines,
                 opts[:with]
               ),
             items <- Map.get(parsed_result, :items, []),
             pipeline_result <-
               Enum.reduce(items, [], fn item, acc ->
                 {piped, _state} = Crawly.Utils.pipe(pipelines, item, %{})

                 [acc | piped]
               end) do
          {response, parsed_result, pipeline_result}
        end
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
end
