defmodule Crawly.Middlewares.DomainFilter do
  @moduledoc """
  Filters out requests which are going outside of the crawled domain.

  The domain that is used to compare against the request url is obtained from the spider's `c:Crawly.Spider.base_url` callback.

  Does not accept any options. Tuple-based configuration optionswill be ignored.

  ### Example Declaration
  ```
  middlewares: [
    Crawly.Middlewares.DomainFilter
  ]
  ```
  """

  @behaviour Crawly.Pipeline
  require Logger

  def run(request, state, _opts \\ []) do
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
