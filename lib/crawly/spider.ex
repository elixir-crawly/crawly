defmodule Crawly.Spider do
  @moduledoc """
  A behavior module for implementing a Crawly Spider

  A Spider is a module which is responsible for defining:
  1. `init/0` function, which must return a keyword list with start_urls list
  2. `base_url/0` function responsible for filtering out requests not related to
      a given website
  3. `parse_item/1` function which is responsible for parsing the downloaded
     request and converting it into items which can be stored and new requests
     which can be scheduled
  """

  @callback init() :: [start_urls: list()]

  @callback base_url() :: binary()

  @callback parse_item(response :: HTTPoison.Response.t()) ::
  Crawly.ParsedItem.t()

end
