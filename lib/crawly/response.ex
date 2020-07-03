defmodule Crawly.Response do
  @moduledoc """
  Define Crawly response structure
  """

  defstruct body: nil,
            headers: [],
            request: nil,
            request_url: nil,
            status_code: nil

  @type t :: %__MODULE__{
               body: term(),
               headers: list(),
               request: Crawly.Request.t(),
               request_url: Crawly.Request.url(),
               status_code: integer()
             }
end
