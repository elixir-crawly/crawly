defmodule Pipelines.WriteToFileTest do
  use ExUnit.Case, async: false

  @binary "Some binary"

  setup do
    on_exit(fn ->
      :meck.unload(IO)
      :meck.unload(File)
    end)
  end

  test "Writes a given item to a file with global config", _context do
    test_pid = self()

    :meck.expect(
      IO,
      :write,
      fn _, item ->
        send(test_pid, item)
        :ok
      end
    )

    :meck.expect(
      File,
      :open,
      fn _path, _opts ->
        {:ok, test_pid}
      end
    )

    pipelines = [
      {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"}
    ]

    item = @binary

    state = %{spider_name: MySpider}

    # run the pipeline
    _result = Crawly.Utils.pipe(pipelines, item, state)

    assert_receive @binary
  end

  test "Writes a given item to a file with tuple config", _context do
    test_pid = self()

    :meck.expect(
      IO,
      :write,
      fn _, item ->
        send(test_pid, item)
        :ok
      end
    )

    :meck.expect(
      File,
      :open,
      fn _path, _opts ->
        {:ok, test_pid}
      end
    )

    pipelines = [
      {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"}
    ]

    item = @binary

    state = %{spider_name: MySpider}

    # run the pipeline
    _result = Crawly.Utils.pipe(pipelines, item, state)

    assert_receive @binary
  end
end
