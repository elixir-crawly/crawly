defmodule CrawldisCommon.RequestQueueTest do
  use ExUnit.Case
  alias CrawldisCommon.RequestQueue
  doctest RequestQueue

  @request %Crawly.Request{url: "http://www.some url.com"}
  setup_all do
    RequestQueue.clear_requests()
  end

  test "add a request to a queue" do
    assert :ok = RequestQueue.add_request(@request)
    assert RequestQueue.count_requests() == 1
    assert RequestQueue.list_requests() |> length == 1
  end

  describe "update" do
    setup [:add_request]

    test "claim a request from the queue" do
      assert :ok = RequestQueue.claim_request()
      assert RequestQueue.count_requests(:claimed) == 1
      assert RequestQueue.list_requests(:unclaimed) |> length == 0
    end

    test "pop a claimed request from queue" do
      assert :ok = RequestQueue.claim_request()
      :timer.sleep(501)
      assert {:ok, %Crawly.Request{} = req} = RequestQueue.pop_claimed_request()
      assert req == @request
      assert RequestQueue.count_requests() == 0
      assert RequestQueue.list_requests() |> length == 0
    end

    test "clear queue" do
      assert :ok = RequestQueue.clear_requests()
      assert RequestQueue.count_requests() == 0
      assert RequestQueue.list_requests() |> length == 0
    end
  end

  defp add_request(_) do
    RequestQueue.add_request(@request)
  end
end
