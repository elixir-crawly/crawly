defmodule Crawly.Spider.Parse do
  @moduledoc """
  The struct that is piped through a spider's declared list of parsers  (that implements the pipeline behaviour) as the parse state.

  The response is loaded into this struct and piped through a parse pipeline if the `:parse` setting key is set.
  """

  defstruct response: nil,
            spider_name: nil,
            selector: nil,
            parsed_item: %Crawly.ParsedItem{}

  @type t :: %__MODULE__{
          spider_name: atom(),
          response: Crawly.Response.t(),
          selector: String.t(),
          parsed_item: %Crawly.ParsedItem{}
        }
end
