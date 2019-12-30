defmodule Crawly.Request do
  @moduledoc """
  Request wrapper

  Defines Crawly request structure, and API to access Crawly.Request fields
  """

  ###===========================================================================
  ### Type definitions
  ###===========================================================================
  defstruct url: nil,
            headers: [],
            prev_response: nil,
            options: [],
            retries: 0,
            middlewares: []

  @type header() :: {key(), value()}
  @type url() :: binary()

  @typep key :: binary()
  @typep value :: binary()
  @type retries :: non_neg_integer()
  @type option :: {atom(), binary()}
  @opaque t :: %__MODULE__{
               url: binary(),
               headers: [header()],
               prev_response: %{},
               retries: 0,
               middlewares: [],
               options: [option()]
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
    %Crawly.Request{url: url, headers: headers, options: options}
  end

  @doc """
  Access url field from Crawly.Request
  """
  @spec url(request) :: url_field
        when request: Crawly.Request.t(),
             url_field: binary()
  def url(request), do: request.url

  @doc """
  Set url field in Crawly.Request
  """
  @spec url(request, new_url) :: url_field
        when request: Crawly.Request.t(),
             new_url: binary(),
             url_field: binary()
  def url(request, new_url), do: %Crawly.Request{request | url: new_url}

  @doc """
  Access headers field from Crawly.Request
  """
  @spec headers(request) :: headers_field
        when request: Crawly.Request.t(),
             headers_field: [term()]
  def headers(request), do: request.headers

  @doc """
  Set headers field in Crawly.Request
  """
  @spec headers(request, new_headers) :: headers_field
        when request: Crawly.Request.t(),
             new_headers: binary(),
             headers_field: binary()
  def headers(request, new_headers),
      do: %Crawly.Request{request | headers: new_headers}

  @doc """
  Access prev_response field from Crawly.Request
  """
  @spec prev_response(request) :: prev_response_field
        when request: Crawly.Request.t(),
             prev_response_field: map()
  def prev_response(request), do: request.prev_response

  @doc """
  Set prev_response field in Crawly.Request
  """
  @spec prev_response(request, new_prev_response) :: prev_response_field
        when request: Crawly.Request.t(),
             new_prev_response: binary(),
             prev_response_field: binary()
  def prev_response(request, prev_response),
      do: %Crawly.Request{request | prev_response: prev_response}

  @doc """
  Access options field from Crawly.Request
  """
  @spec options(request) :: options_field
        when request: Crawly.Request.t(),
             options_field: [term()]
  def options(request), do: request.options

  @doc """
  Set options field in Crawly.Request
  """
  @spec options(request, new_options) :: options_field
        when request: Crawly.Request.t(),
             new_options: binary(),
             options_field: binary()
  def options(request, new_options),
      do: %Crawly.Request{request | options: new_options}
      
  @doc """
  Access retries field from Crawly.Request
  """
  @spec retries(request) :: retries_field
        when request: Crawly.Request.t(),
             retries_field: [term()]
  def retries(request), do: request.headers

  @doc """
  Set retries field in Crawly.Request
  """
  @spec retries(request, new_retries) :: retries_field
        when request: Crawly.Request.t(),
             new_retries: binary(),
             retries_field: binary()
  def retries(request, new_retries),
      do: %Crawly.Request{request | retries: new_retries}

  @doc """
  Access middlewares field from Crawly.Request
  """
  @spec middlewares(request) :: middlewares_field
        when request: Crawly.Request.t(),
             middlewares_field: [term()]
  def middlewares(request), do: request.middlewares

  @doc """
  Set middlewares field in Crawly.Request
  """
  @spec middlewares(request, new_middlewares) :: middlewares_field
        when request: Crawly.Request.t(),
             new_middlewares: binary(),
             middlewares_field: binary()
  def middlewares(request, new_middlewares),
      do: %Crawly.Request{request | middlewares: new_middlewares}
end
