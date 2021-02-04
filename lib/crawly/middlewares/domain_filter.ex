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
    info =
      state.spider_name
      |> Crawly.Engine.get_spider_info()

    base_url =
      if info != nil and info.template != nil,
        do: info.template.base_url(),
        else: nil

    host =
      request.url
      |> URI.parse()
      |> Map.get(:host)

    case do_filter(base_url, host) do
      :ok ->
        {request, state}

      :drop ->
        Logger.debug(
          "Dropping request: #{inspect(request.url)} (domain filter)"
        )

        {false, state}
    end
  end

  defp do_filter("" <> base_url, "" <> host) do
    if String.contains?(base_url, host), do: :ok, else: :drop
  end

  defp do_filter(_base_url, _host), do: :drop
end
