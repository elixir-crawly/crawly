defmodule Middlewares.RequestOptionsTest do
  use ExUnit.Case, async: false

  test "Options are added to request settings" do
    req = Crawly.Request.new("http://example.com")

    middlewares = [
      {
        Crawly.Middlewares.RequestOptions,
        [timeout: 30_000, recv_timeout: 15000]
      }
    ]

    {new_request, _state} = Crawly.Utils.pipe(middlewares, req, %{})

    assert [timeout: 30000, recv_timeout: 15000] == new_request.options
  end
end
