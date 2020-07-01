defmodule DataStorageTest do
  use ExUnit.Case, async: false

  setup do
    name = :test_crawler
    {:ok, pid} = Crawly.DataStorage.start_worker(name)

    on_exit(fn ->
      :ok =
        DynamicSupervisor.terminate_child(Crawly.DataStorage.WorkersSup, pid)
    end)

    {:ok, %{crawler: name}}
  end

  test "Can store data item", context do
    Crawly.DataStorage.store(context.crawler, %{
      title: "test title",
      author: "me",
      time: "Now",
      url: "http://example.com"
    })

    {:stored_items, 1} = Crawly.DataStorage.stats(context.crawler)
  end

  test "Duplicates are not stored", context do
    Crawly.DataStorage.store(context.crawler, %{
      title: "test title",
      author: "me",
      time: "Now",
      url: "http://example.com"
    })

    Crawly.DataStorage.store(context.crawler, %{
      title: "test title",
      author: "me",
      time: "Now",
      url: "http://example.com"
    })

    {:stored_items, 1} = Crawly.DataStorage.stats(context.crawler)
  end

  test "Items without all required fields are dropped", context do
    Crawly.DataStorage.store(context.crawler, %{
      author: "me",
      time: "Now",
      url: "http://example.com"
    })

    {:stored_items, 0} = Crawly.DataStorage.stats(context.crawler)
  end

  test "Items without all required fields are dropped nils", context do
    Crawly.DataStorage.store(context.crawler, %{
      title: "title",
      author: nil,
      time: "Now",
      url: "http://example.com"
    })

    {:stored_items, 0} = Crawly.DataStorage.stats(context.crawler)
  end

  test "Starting child worker twice", context do
    result = Crawly.DataStorage.start_worker(context.crawler)
    assert result == {:error, :already_started}
  end

  test "Stats for not running spiders" do
    result = Crawly.DataStorage.stats(:unkown)
    assert result == {:error, :data_storage_worker_not_running}
  end
end
