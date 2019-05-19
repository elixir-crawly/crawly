defmodule DataStorageWorkerTest do
  use ExUnit.Case

  setup do
    name = :test_crawler
    {:ok, pid} = Crawly.DataStorage.start_worker(name)

    on_exit(fn ->
      :ok = TestUtils.stop_process(pid)
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

  test "Items are stored in JSON after json_encoder pipeline", context do
    item = %{
      title: "test_title",
      author: "me",
      time: "Now",
      url: "http://example.com"
    }

    :ok = Crawly.DataStorage.store(context.crawler, item)

    # TODO: Rewrite to avoid sleep
    Process.sleep(3000)
    base_path = Application.get_env(:crawly, :base_store_path, "/tmp/")
    {:ok, data} = File.read("#{base_path}#{inspect(context.crawler)}.jl")
    {:ok, decoded_data} = Poison.decode(data, %{keys: :atoms!})
    assert item == decoded_data
  end

  test "Starting child worker twice", context do
    result = Crawly.DataStorage.start_worker(context.crawler)
    assert result == {:error, :already_started}
  end

  test "Stats for not running spiders" do
    result = Crawly.DataStorage.stats(:unkown)
    assert result == {:error, :data_storage_worker_not_running}
  end

  test "Duplicates pipline is inactive when item_id is not set", context do
    :meck.expect(Application, :get_env, fn :crawly, :item_id -> :undefined end)

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

    Process.sleep(1000)
    {:stored_items, 2} = Crawly.DataStorage.stats(context.crawler)
    :meck.unload(Application)
  end
end
