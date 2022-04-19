defmodule Middlewares.AutoCookiesManagertest do
  use ExUnit.Case, async: false

  test "Cookies are not added when there is no prev_response data" do
    req = Crawly.Request.new("http://example.com")
    middlewares = [Crawly.Middlewares.AutoCookiesManager]

    {new_request, _state} = Crawly.Utils.pipe(middlewares, req, %{})

    assert [] == new_request.headers
  end

  test "Cookies are not added when there is no set cookie in prev response" do
    prev_response = %HTTPoison.Response{
      body: "test",
      headers: [
        {"Date", "Wed, 26 Feb 2020 21:06:52 GMT"},
        {"Content-Type", "text/html;charset=utf-8"},
        {"Transfer-Encoding", "chunked"},
        {"Connection", "keep-alive"}
      ]
    }

    req =
      "http://example.com"
      |> Crawly.Request.new()
      |> Map.put(:prev_response, prev_response)

    middlewares = [Crawly.Middlewares.AutoCookiesManager]

    {new_request, _state} = Crawly.Utils.pipe(middlewares, req, %{})

    assert [] == new_request.headers
  end

  test "Cookies are taken into account" do
    prev_response = %HTTPoison.Response{
      body: "test",
      headers: [
        {"Set-Cookie", "bucket=desktop; Domain=.example.com; path=/;"},
        {"Set-Cookie", "OT_1073742440=72; SameSite=None; Secure"}
      ]
    }

    req =
      "http://example.com"
      |> Crawly.Request.new()
      |> Map.put(:prev_response, prev_response)

    middlewares = [Crawly.Middlewares.AutoCookiesManager]

    {new_request, _state} = Crawly.Utils.pipe(middlewares, req, %{})

    cookie = :proplists.get_value("Cookie", new_request.headers, [])

    assert Enum.sort(String.split(cookie, "; ")) ==
             Enum.sort(["bucket=desktop", "OT_1073742440=72"])
  end
end
