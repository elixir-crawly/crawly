defmodule Crawly do
  @moduledoc """
  Crawly is a fast high-level web crawling & scraping framework for Elixir.
  """

  require Logger

  @doc """
  Fetches a given url. This function is mainly used for the spiders development
  when you need to get individual pages and parse them.

  The fetched URL is being converted to a request, and the request is piped
  through the middlewares specified in a config (with the exception of
  `Crawly.Middlewares.DomainFilter`, `Crawly.Middlewares.RobotsTxt`)

  Provide a spider with the `:with` option to fetch a given webpage using that spider.

  ### Fetching with a spider
  To fetch a response from a url with a spider, define your spider, and pass the module name to the `:with` option.

    iex> Crawly.fetch("https://www.example.com", with: MySpider)
    {%HTTPoison.Response{...}, %{...}, [...], %{...}}

  Using the `:with` option will return a 4 item tuple:

  1. The HTTPoison response
  2. The result returned from the `parse_item/1` callback
  3. The list of items that have been processed by the declared item pipelines.
  4. The pipeline state, included for debugging purposes.
  """
  @type with_opt :: {:with, nil | module()}
  @type request_opt :: {:request_options, list(Crawly.Request.option())}
  @type headers_opt :: {:headers, list(Crawly.Request.header())}

  @type parsed_item_result :: Crawly.ParsedItem.t()
  @type parsed_items :: list(any())
  @type pipeline_state :: %{optional(atom()) => any()}
  @type spider :: module()

  @spec fetch(url, opts) ::
          HTTPoison.Response.t()
          | {HTTPoison.Response.t(), parsed_item_result, parsed_items,
             pipeline_state}
        when url: binary(),
             opts: [
               with_opt
               | request_opt
               | headers_opt
             ]
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
    {:ok, {response, _}} = Crawly.Worker.get_response({request, opts[:with]})

    case opts[:with] do
      nil ->
        # no spider provided, return response as is
        response

      _ ->
        # spider provided, send response through  parse_item callback, pipe through the pipelines
        with {:ok, {parsed_result, _, _}} <-
               Crawly.Worker.parse_item({response, opts[:with]}),
             pipelines <-
               Crawly.Utils.get_settings(
                 :pipelines,
                 opts[:with]
               ),
             items <- Map.get(parsed_result, :items, []),
             {pipeline_result, pipeline_state} <-
               Enum.reduce(items, {[], %{}}, fn item, {acc, state} ->
                 {piped, state} = Crawly.Utils.pipe(pipelines, item, state)

                 if piped == false do
                   # dropped
                   {acc, state}
                 else
                   {[piped | acc], state}
                 end
               end) do
          {response, parsed_result, pipeline_result, pipeline_state}
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
        Logger.debug("Could not load spiders: #{inspect(error)}")
    end
  end
end
