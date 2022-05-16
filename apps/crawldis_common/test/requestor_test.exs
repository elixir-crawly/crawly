defmodule CrawldisCommon.RequestorTest do
  use ExUnit.Case
  alias CrawldisCommon.{RequestQueue, Requestor}
  doctest RequestQueue

  @id "123"
  @request %Crawly.Request{url: "http://www.some url.com"}
  setup_all do
    RequestQueue.clear_requests()
  end
  setup do
    start_supervised!({Requestor, [@id]})
    :ok
  end
  setup [:add_request]
  test "requestor consumes requests from the request queue" do
    :timer.sleep(1000)
    assert RequestQueue.count_requests(:claimed) == 1
    :timer.sleep(1000)
  end

  defp add_request(_) do
    RequestQueue.add_request(@request)
  end
end
