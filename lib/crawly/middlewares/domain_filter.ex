defmodule Crawly.Middlewares.DomainFilter do
  @moduledoc """
  Filters out requests which are going outside of the crawled domain
  """

  @behaviour Crawly.Pipeline
  require Logger

  def run(request, state) do
    base_url = state.spider_name.base_url()

    case String.contains?(request.url, base_url) do
      false ->
        Logger.debug(
          "Dropping request: #{inspect(request.url)} (domain filter)"
        )

        {false, state}

      true ->
        {request, state}
    end
  end
end
