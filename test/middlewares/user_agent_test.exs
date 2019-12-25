defmodule Middlewares.UserAgentTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      Application.put_env(:crawly, :user_agents, nil)
    end)
  end

  test "Adds a user agent to request header with global config" do
    Application.put_env(:crawly, :user_agents, ["My Custom Bot"])
    middlewares = [Crawly.Middlewares.UserAgent]
    req = %Crawly.Request{}
    state = %{}

    {req, _state} = Crawly.Utils.pipe(middlewares, req, state)

    {_, ua} =
      Map.get(req, :headers)
      |> Enum.find(fn {name, _value} -> name == "User-Agent" end)

    assert ua == "My Custom Bot"
  end

  test "Adds a user agent to request header with tuple config" do
    middlewares = [
      {Crawly.Middlewares.UserAgent, user_agents: ["My Custom Bot"]}
    ]

    req = %Crawly.Request{}
    state = %{}

    {req, _state} = Crawly.Utils.pipe(middlewares, req, state)

    {_, ua} =
      Map.get(req, :headers)
      |> Enum.find(fn {name, _value} -> name == "User-Agent" end)

    assert ua == "My Custom Bot"
  end
end
