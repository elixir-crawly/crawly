defmodule Crawly.Spider.Parse do
  @moduledoc """
  The struct that is piped through a spider's parse pipelines.

  The response is loaded into this struct and piped through a parse pipeline if the `:parse` setting key is set.
  """

  defstruct response: nil

  @type t :: %__MODULE__{
          response: Crawly.Response(),
        }
end
