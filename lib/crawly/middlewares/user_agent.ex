defmodule Crawly.Middlewares.UserAgent do
  @moduledoc """
  Set/Rotate user agents for crawling. The user agents are read from
  :crawly, :user_agents sessions.

  The default value for the user agent is: Crawly Bot 1.0

  Rotation is determined through `Enum.random/1`.
  ### Options
  - `:user_agents`, optional. A list of user agent strings to rotate. Defaults to "Crawly Bot 1.0".

  ### Example Declaration
  ```
  middlewares: [
    {UserAgent, user_agents: ["My Custom Bot"] }
  ]
  ```
  """
  require Logger

  def run(request, state, opts \\ []) do
    opts = Enum.into(opts, %{user_agents: nil})

    new_headers = List.keydelete(request.headers, "User-Agent", 0)

    user_agents = Map.get(opts, :user_agents, ["Crawly Bot 1.0"])

    useragent = Enum.random(user_agents)

    new_request =
      Map.put(request, :headers, [{"User-Agent", useragent} | new_headers])

    {new_request, state}
  end
end
