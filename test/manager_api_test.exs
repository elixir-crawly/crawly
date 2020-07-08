defmodule ManagerAPITest do
  use ExUnit.Case, async: false

  alias Crawly.ManagerAPI
  alias Features.Manager.TestSpider

  setup do
    Application.put_env(:crawly, :concurrent_requests_per_domain, 1)
    :ok = Crawly.Engine.start_spider(TestSpider)

    :meck.expect(HTTPoison, :get, fn _, _, _ ->
      {:ok,
       %HTTPoison.Response{
         status_code: 200,
         body: "Some page",
         headers: [],
         request: %{}
       }}
    end)

    on_exit(fn ->
      :meck.unload()
      Crawly.Engine.stop_spider(TestSpider)
    end)
  end

  test "it is possible to add more workers to a spider" do
    spider_name = TestSpider
    initial_number_of_workers = 1

    assert initial_number_of_workers ==
             DynamicSupervisor.count_children(spider_name)[:workers]

    workers = 2
    assert :ok == ManagerAPI.add_workers(spider_name, workers)

    pid = Crawly.Engine.get_manager(spider_name)
    state = :sys.get_state(pid)
    assert spider_name == state.name

    assert initial_number_of_workers + workers ==
             DynamicSupervisor.count_children(spider_name)[:workers]
  end

  test "returns error when spider doesn't exist" do
    assert {:error, :spider_non_exist} ==
             ManagerAPI.add_workers(Manager.NonExistentSpider, 2)
  end
end
