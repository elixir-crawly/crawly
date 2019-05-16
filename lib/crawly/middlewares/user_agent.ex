defmodule Crawly.Middlewares.UserAgent do
  @moduledoc """
  Set/Rotate user agents for crawling. The user agents are read from
  :crawly, :user_agents sessions.

  The default value for the user agent is: Crawly Bot 1.0
  """
  require Logger

  def run(request, state) do
    new_headers = List.keydelete(request.headers, "User-Agent", 0)
    user_agents = Application.get_env(:crawly, :user_agents, ["Crawly Bot 1.0"])
    useragent = Enum.random(user_agents)

    new_request =
      Map.put(request, :headers, [{"User-Agent", useragent} | new_headers])
    {new_request, state}
  end
end
