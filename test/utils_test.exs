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

  test "Build absolute url test" do
    url = Crawly.Utils.build_absolute_url("/url1", "http://example.com")
    assert url == "http://example.com/url1"
  end

  test "Build absolute urls test" do
    paths = ["/path1", "/path2"]
    result = Crawly.Utils.build_absolute_urls(paths, "http://example.com")

    assert result == ["http://example.com/path1", "http://example.com/path2"]
  end
end
