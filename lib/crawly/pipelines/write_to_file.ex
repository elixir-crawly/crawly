defmodule Crawly.Pipelines.WriteToFile do
  @moduledoc """
  Stores a given item into Filesystem

  Pipeline Lifecycle:
  1. When run (by `Crawly.Utils.pipe`), creates a file descriptor if not already created.
  2. Performs the write operation
  3. File descriptor is reused by passing it through the pipeline state with `:write_to_file_fd`

  Note: `File.close` is not necessary due to the file descriptor being automatically closed upon the end of a the parent process.
  Refer to https://github.com/oltarasenko/crawly/pull/19#discussion_r350599526 for relevant discussion.
  """

  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, %{write_to_file_fd: fd} = state) do
    :ok = write(fd, item)
    {item, state}
  end

  # No active FD
  def run(item, state) do
    fd = open_fd(state.spider_name)
    :ok = write(fd, item)
    {item, Map.put(state, :write_to_file_fd, fd)}
  end

  defp open_fd(spider_name) do
    config =
      Application.get_env(
        :crawly,
        Crawly.Pipelines.WriteToFile,
        Keyword.new()
      )

    folder = Keyword.get(config, :folder, System.tmp_dir!())
    extension = Keyword.get(config, :extension, "jl")

    filename = "#{inspect(spider_name)}.#{extension}"
    # Open file descriptor to write items
    {:ok, io_device} =
      File.open(
        Path.join([folder, filename]),
        [
          :binary,
          :write,
          :delayed_write,
          :utf8
        ]
      )

    io_device
  end

  # Performs the write operation
  @spec write(io, item) :: :ok
        when io: File.io_device(),
             item: any()
  defp write(io, item) do
    try do
      IO.write(io, item)
      IO.write(io, "\n")
    catch
      error, reason ->
        stacktrace = :erlang.get_stacktrace()

        Logger.error(
          "Could not write item: #{inspect(error)}, reason: #{inspect(reason)}, stacktrace: #{
            inspect(stacktrace)
          }
          "
        )
    end
  end
end
