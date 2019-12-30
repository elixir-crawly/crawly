defmodule Crawly.Fetchers.Fetcher do
  @moduledoc """
  A behavior module for defining Crawly Fetchers

  A fetcher is expected to implement a fetch callback which should take
  Crawly.Request, HTTP client options and return Crawly.Response.
  """

  @callback fetch(request, options) :: {:ok, response} | {:error, reason}
            when request: Crawly.Request.t(),
                 response: Crawly.Response.t(),
                 options: map(),
                 reason: term()
end
