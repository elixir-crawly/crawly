defmodule DataStorageTest do
  use ExUnit.Case, async: false
  @name "my_data_storage_test_spider"
  @other_name "diff_spider"
  @item %{
    title: "test title",
    author: "me",
    time: "Now",
    url: "http://example.com"
  }
  @crawl_id "my_crawl_id"
  setup do
    # create a mock pipeline
    :meck.new(PipelineMock, [:non_strict])

    :meck.expect(Crawly.Utils, :get_settings, fn :pipelines, _spider_name, _ ->
      [PipelineMock]
    end)

    {:ok, pid} = Crawly.DataStorage.start_worker(@name, @crawl_id)

    on_exit(fn ->
      :meck.unload()

      :ok =
        DynamicSupervisor.terminate_child(Crawly.DataStorage.WorkersSup, pid)
    end)

    :ok
  end

  describe "pipeline works" do
    setup do
      :meck.expect(PipelineMock, :run, fn item, state ->
        {item, state}
      end)
    end

    test "Can store data item" do
      assert :ok = Crawly.DataStorage.store(@name, @item)
      assert {:stored_items, 1} = Crawly.DataStorage.stats(@name)
      assert :meck.history(PipelineMock) |> length() == 1
    end
  end

  test "Starting child worker twice returns error tuple" do
    result = Crawly.DataStorage.start_worker(@name, @crawl_id)
    assert result == {:error, :already_started}
  end

  test "Stats for not running spiders returns error tuple" do
    assert {:error, :data_storage_worker_not_running} =
             Crawly.DataStorage.stats(@other_name)
  end

  describe "pipeline drops" do
    setup do
      :meck.expect(PipelineMock, :run, fn _item, state ->
        {false, state}
      end)
    end

    test "Dropped item are not stored" do
      Crawly.DataStorage.store(@name, @item)
      {:stored_items, 0} = Crawly.DataStorage.stats(@name)
    end
  end
end
