defmodule Crawly.Middlewares.CookiesManager do
  require Logger

  def run(request, state) do
    case request.prev_response do
      nil ->
        {request, state}
      _ ->
        IO.puts("Cookies middleware is not implemented")
        {request, state}
    end

  end
end
