defmodule Crawly.Middlewares.RequestOptions do
  @moduledoc """
  Request settings middleware

  Allows to specify HTTP request settings like follow_redirect, or request
  timeout.
  
  If using `HTTPoisonFetcher` (the default), please refer to the [HTTPoison Request documentation](https://hexdocs.pm/httpoison/HTTPoison.Request.html#content) for full list of `:options`. 
  
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
   {Crawly.Middlewares.RequestOptions, [proxy: {"https://my_host.com", 3000}, proxy_auth: {"my_user", "my_password}]}
  ]
  ```
  
  """
  @behaviour Crawly.Pipeline

  def run(request, state, options \\ []) do
    {%Crawly.Request{request| options: options}, state}
  end
end
