defmodule Crawly.Middlewares.RequestOptions do
  @moduledoc """
  Request settings middleware

  Allows to specify HTTP request settings like follow_redirect, or request
  timeout.

  If using `HTTPoisonFetcher` (the default), please refer to the [HTTPoison Request documentation](https://hexdocs.pm/httpoison/HTTPoison.Request.html#content) for full list of `:options`.

  The two timeout options, in milliseconds:

    * `:timeout` is how long to wait to connect.
    * `:recv_timeout` is how long to wait for the response.

  `HTTPoisonFetcher` applies `timeout: 8_000` and `recv_timeout: 5_000`
  unless they are set here or on the request. Use `recv_timeout: :infinity`
  to wait without a limit.

  ## Example Usage
  ### Example Declaration
  ```
  middlewares: [
    {Crawly.Middlewares.RequestOptions, [timeout: 30_000, recv_timeout: 15000]}
  ]
  ```
  ### Declaring proxy settings
  ```
  middlewares: [
   {Crawly.Middlewares.RequestOptions, [proxy: {"https://my_host.com", 3000}, proxy_auth: {"my_user", "my_password"}]}
  ]
  ```

  """
  @behaviour Crawly.Pipeline

  def run(%Crawly.Request{} = request, state, options \\ []) do
    {%Crawly.Request{
       request
       | options: Keyword.merge(options, request.options)
     }, state}
  end
end
