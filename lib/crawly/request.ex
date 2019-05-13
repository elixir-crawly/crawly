defmodule Crawly.Request do
  @moduledoc """
  Request wrapper

  Defines Crawly request structure.
  """
  defstruct url: nil, headers: [], prev_response: nil, options: []

  @type header() :: {key(), value()}
  @typep key :: binary()
  @typep value :: binary()

  @type option :: {atom(), binary()}

  @type t :: %__MODULE__{
    url: binary(),
    headers: [header()],
    prev_response: %{},
    options: [option()]
  }
end
