defmodule Crawly.Middlewares.RequestOptions do
  @moduledoc """
  Request settings middleware

  Allows to specify HTTP request settings like follow_redirect, or request
  timeout.

  ### Example Declaration
  ```
  middlewares: [
    {Crawly.Middlewares.RequestOptions, [timeout: 30_000, recv_timeout: 15000]}
  ]
  ```
  """
  @behaviour Crawly.Pipeline

  def run(request, state, options \\ []) do
    {%Crawly.Request{request| options: options}, state}
  end
end