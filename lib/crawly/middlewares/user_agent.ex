defmodule Crawly.Middlewares.UserAgent do
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
