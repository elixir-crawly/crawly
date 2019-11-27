defmodule Pipelines.WriteToFileTest do
  use ExUnit.Case, async: false

  # creates a string with a unique timestamp
  @binary "some binary to write to the csv #{:os.system_time(:seconds)}"

  test "WriteToFile writes a given item to a file", _context do
    Application.put_env(:crawly, Crawly.Pipelines.WriteToFile,
      folder: "/tmp",
      extension: "csv"
    )

    pipelines = [
      Crawly.Pipelines.WriteToFile
    ]

    item = @binary

    state = %{spider_name: MySpider}

    # run the pipeline
    {item, %{write_to_file_fd: fd} = state} =
      Crawly.Utils.pipe(pipelines, item, state)

    # write changes to the file
    File.close(fd)

    # returns the same item
    assert item == @binary

    # file descriptor is set in state
    assert state.write_to_file_fd

    # assert changes to the file
    tmp_dir = System.tmp_dir!()
    output_file_path = Path.join(tmp_dir, "MySpider.csv")
    assert File.read!(output_file_path) =~ @binary
  end
end
