defmodule Crawly.Middlewares.SameDomainFilter do
  @moduledoc """
  Filters out requests which are going outside of the crawled domain.

  The domain that is used to compare against the request url is obtained from
  the previous response, so it ends up being the spider's start_url. Spider's
  base_url is not evaluated.

  Does not accept any options. Tuple-based configuration optionswill be ignored.

  ### Example Declaration
  ```
  middlewares: [
    Crawly.Middlewares.SameDomainFilter
  ]
  ```
  """

  @behaviour Crawly.Pipeline
  require Logger

  def run(request, state, _opts \\ []) do
    base_url = get_in(request, [Access.key(:prev_response), Access.key(:request_url)])

    case base_url do
      nil ->
        # no previous request, so we assume it's the first one and let it pass
        {request, state}

      _ ->
        base_host = URI.parse(base_url).host
        request_host = URI.parse(request.url).host

        case request_host != nil and base_host == request_host do
          false ->
            Logger.debug("Dropping request: #{inspect(request.url)} (domain filter)")
            {false, state}

          true ->
            {request, state}
        end
    end
  end
end
