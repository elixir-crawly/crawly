defmodule Crawly.Request do
  @moduledoc """
  Request wrapper

  Defines Crawly request structure.
  """
  ###===========================================================================
  ### Type definitions
  ###===========================================================================
  defstruct url: nil,
            headers: [],
            prev_response: nil,
            options: [],
            middlewares: [],
            retries: 0

  @type header() :: {key(), value()}
  @type url() :: binary()

  @typep key :: binary()
  @typep value :: binary()

  @type option :: {atom(), binary()}

  @type t :: %__MODULE__{
               url: url(),
               headers: [header()],
               prev_response: %{},
               options: [option()],
               middlewares: [atom()],
               retries: non_neg_integer()
             }

  ###===========================================================================
  ### API functions
  ###===========================================================================
  @doc """
  Create new Crawly.Request from url, headers and options
  """
  @spec new(url, headers, options) :: request
        when url: binary(),
             headers: [term()],
             options: [term()],
             request: Crawly.Request.t()

  def new(url, headers \\ [], options \\ []) do
    # Define a list of middlewares which are used by default to process
    # incoming requests
    default_middlewares = [
      Crawly.Middlewares.DomainFilter,
      Crawly.Middlewares.RequestOptions,
      Crawly.Middlewares.UniqueRequest,
      Crawly.Middlewares.RobotsTxt
    ]

    middlewares =
      Application.get_env(:crawly, :middlewares, default_middlewares)

    new(url, headers, options, middlewares)
  end

  @doc """
  Same as Crawly.Request.new/3 from but allows to specify middlewares as the 4th
  parameter.
  """
  @spec new(url, headers, options, middlewares) :: request
        when url: binary(),
             headers: [term()],
             options: [term()],
             middlewares: [term()], # TODO: improve typespec here
             request: Crawly.Request.t()
  def new(url, headers, options, middlewares) do
    %Crawly.Request{
      url: url,
      headers: headers,
      options: options,
      middlewares: middlewares
    }
  end
end
