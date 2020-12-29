defmodule Crawly.Parsers.RequestsExtractor do
  @moduledoc """
  Links extractor parser helper, which simplifies the process
  of links extraction.
  """

  alias Crawly.Spider.Parse

  def parse(parse_struct) do
    %Parse{response: response, selector: selector} = parse_struct

    requests =
      response.body
      |> Floki.parse_document!()
      |> Floki.find(selector)
      |> Floki.attribute("href")
      |> Crawly.Utils.build_absolute_urls(response.request_url)
      |> Crawly.Utils.requests_from_urls()

    new_parsed_requests = requests ++ parse_struct.parsed_item.requests

    new_parsed_item = %Crawly.ParsedItem{
      parse_struct.parsed_item
      | requests: new_parsed_requests
    }

    %Parse{parse_struct | parsed_item: new_parsed_item}
  end
end
