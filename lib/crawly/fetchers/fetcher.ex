defmodule Crawly.Fetchers.Fetcher do
  @moduledoc """
  A behavior module for defining Crawly Fetchers

  A fetcher is expected to implement a fetch callback which should return a
  Crawly.Response
  """

  @callback fetch(request) :: {:ok, response} | {:error, reason}
            when request: Crawly.Request.t(),
                 response: Crawly.Response.t(),
                 reason: term()
end
