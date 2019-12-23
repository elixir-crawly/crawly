defmodule Crawly.Request do
  @moduledoc """
  Request wrapper

  Defines Crawly request structure.
  """
  defstruct url: nil, headers: [], prev_response: nil, options: []

  @type header() :: {key(), value()}
  @type url() :: binary()

  @typep key :: binary()
  @typep value :: binary()

  @type option :: {atom(), binary()}

  @type t :: %__MODULE__{
    url: url(),
    headers: [header()],
    prev_response: %{},
    options: [option()]
  }
end
