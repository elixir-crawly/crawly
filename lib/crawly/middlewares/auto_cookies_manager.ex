defmodule Crawly.Middlewares.AutoCookiesManager do
  @moduledoc """
  Set/update cookies for requests. The cookies are being automatically picked
  up from prev_responses stored by Crawly. Only name/value pairs are taken into
  account, all other options like domain, secure and others are ignored.

  ### Example Declaration
  ```
  middlewares: [
    Crawly.Middlewares.AutoCookiesManager
  ]
  ```
  """
  require Logger

  def run(request, state) do
    known_cookies = Map.get(state, :cookies_manager_seen_cookies, MapSet.new())

    new_cookies =
      case request.prev_response do
        nil ->
          []

        prev_response ->
          :proplists.get_all_values("Set-Cookie", prev_response.headers)
      end

    new_known_cookies =
      Enum.reduce(new_cookies, known_cookies, fn cookie, acc ->
        # Take the first name/value pair and store it
        cookie = hd(String.split(cookie, ";"))
        MapSet.put(acc, cookie)
      end)

    case MapSet.size(new_known_cookies) do
      0 ->
        # No cookies required by the site
        {request, state}

      _other ->
        cookies = new_known_cookies |> MapSet.to_list() |> Enum.join("; ")
        new_request = Map.put(request, :headers, [{"Cookie", cookies}])

        new_state =
          Map.put(state, :cookies_manager_seen_cookies, new_known_cookies)

        {new_request, new_state}
    end
  end
end
