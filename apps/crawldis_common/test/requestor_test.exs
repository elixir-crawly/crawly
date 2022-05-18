defmodule CrawldisCommon.RequestorTest do
  use ExUnit.Case
  alias CrawldisCommon.RequestorTest.TestExtractor
  alias CrawldisCommon.{RequestQueue, Requestor}
  doctest RequestQueue

  @id "123"
  @request %Crawly.Request{
    url: "https://www.exmaple.com",
    fetcher: Crawly.Fetchers.HTTPoisonFetcher,
    extractors: [TestExtractor]
  }
  setup_all do
    :meck.expect(HTTPoison, :get, fn _, _ , _->
      {:ok, %HTTPoison.Response{
      body: "some body"
    }}
  end)
  end
  setup do
    RequestQueue.clear_requests()
    start_supervised!({Requestor, [@id]})
    :ok
  end
  test "requestor claims requests from the request queue" do

    RequestQueue.add_request(@request)

    :timer.sleep(800)
    assert RequestQueue.count_requests(:claimed) == 1
    :timer.sleep(500)
    assert :meck.called(HTTPoison, :get, [:_, :_, :_])
    list = RequestQueue.list_requests()
    refute list |> Enum.any?(&(&1.request.url =~ "example.com"))
    # sends new requests to queue
    assert list |> Enum.any?(&(&1.request.url =~ "example2.com"))
    # TODO: sends new items to processors
  end
  defmodule TestExtractor do
    @behaviour Crawly.Pipeline

    @request %Crawly.Request{
      url: "https://www.example2.com",
      fetcher: Crawly.Fetchers.HTTPoisonFetcher,
    }

    def run(item, state) do
      item = Map.put(item, :requests, [@request])
      {item, state}
    end
  end


end
