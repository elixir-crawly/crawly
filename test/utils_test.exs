defmodule UtilsTest do
  use ExUnit.Case

  test "Request from url" do
    requests = Crawly.Utils.request_from_url("https://test.com")
    assert requests == %Crawly.Request{url: "https://test.com", headers: []}
  end

  test "Requests from urls" do
    requests =
      Crawly.Utils.requests_from_urls([
        "https://test.com",
        "https://example.com"
      ])

    assert requests == [
             %Crawly.Request{url: "https://test.com", headers: []},
             %Crawly.Request{url: "https://example.com", headers: []}
           ]
  end
end
