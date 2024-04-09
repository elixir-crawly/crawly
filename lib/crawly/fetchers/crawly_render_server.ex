defmodule Crawly.Fetchers.CrawlyRenderServer do
  @moduledoc """
  Implements Crawly.Fetchers.Fetcher behavior for Crawly Render Server
  Javascript rendering.

  Crawly Render Server is a lightweight puppeteer based Javascript rendering
  engine server. Quite experimental. See more:
  https://github.com/elixir-crawly/crawly-render-server

  It exposes /render endpoint that renders JS on incoming requests. For example:
  curl -X POST \
    http://localhost:3000/render \
    -H 'Content-Type: application/json' \
    -d '{
       "url": "https://example.com",
       "headers": {"User-Agent": "Custom User Agent"}
  }'

  In this case you have to configure the fetcher in the following way:
  `fetcher: {Crawly.Fetchers.CrawlyRenderServer, [base_url: "http://localhost:3000/render"]}`
  """
  @behaviour Crawly.Fetchers.Fetcher

  require Logger

  def fetch(request, client_options) do
    base_url =
      case Keyword.get(client_options, :base_url, nil) do
        nil ->
          Logger.error(
            "The base_url is not set. CrawlyRenderServer can't be used! " <>
              "Please set :base_url in fetcher options to continue. " <>
              "For example: " <>
              "fetcher: {Crawly.Fetchers.CrawlyRenderServer, [base_url: <url>]}"
          )

          raise RuntimeError

        base_url ->
          base_url
      end

    req_body =
      Poison.encode!(%{
        url: request.url,
        headers: Map.new(request.headers)
      })

    case HTTPoison.post(
           base_url,
           req_body,
           [{"content-type", "application/json"}],
           request.options
         ) do
      {:ok, response} ->
        js = Poison.decode!(response.body)

        new_response = %HTTPoison.Response{
          body: Map.get(js, "page"),
          status_code: Map.get(js, "status"),
          headers: Map.get(js, "headers"),
          request_url: request.url,
          request: request
        }

        {:ok, new_response}

      err ->
        err
    end
  end
end
