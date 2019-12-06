defmodule Pipelines.WriteToFileTest do
  use ExUnit.Case, async: false

  @binary "Some binary"

  setup do
    on_exit(
      fn ->
        Application.put_env(:crawly, :'Crawly.Pipelines.WriteToFile', nil)
      end
    )
  end

  test "Writes a given item to a file", _context do
    test_pid = self()
    :meck.expect(
      IO,
      :write,
      fn (_, item) ->
        send(test_pid, item)
        :ok
      end
    )

    Application.put_env(
      :crawly,
      Crawly.Pipelines.WriteToFile,
      folder: "/tmp",
      extension: "csv"
    )

    pipelines = [
      Crawly.Pipelines.WriteToFile
    ]

    item = @binary

    state = %{spider_name: MySpider}

    # run the pipeline
    _result =
      Crawly.Utils.pipe(pipelines, item, state)

    assert_receive @binary
  end
end
