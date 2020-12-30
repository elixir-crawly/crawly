defmodule Crawly.ParsedItem do
  @moduledoc """
  Defines the structure of spider's result.

  ## Usage with Parsers
  A `%ParsedItem{}` is piped through each parser pipeline module when it is declared. Refer to `Crawly.Pipeline` for further documentation.
  """

  defstruct items: [], requests: []

  @type item() :: map()
  @type t :: %__MODULE__{
          items: [item()],
          requests: [Crawly.Request.t()]
        }
end
