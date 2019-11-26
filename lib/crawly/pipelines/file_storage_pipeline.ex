defmodule Crawly.Pipelines.FileStoragePipeline do
  @moduledoc """
  Stores a given item into Filesystem
  """

  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, %{file_storage_pipeline_fd: fd} = state) do
    :ok = write(fd, item)
    {item, state}
  end

  # No active FD
  def run(item, state) do
    fd = open_fd(state.spider_name)
    :ok = write(fd, item)
    {item, Map.put(state, :file_storage_pipeline_fd, fd)}
  end

  defp open_fd(spider_name) do
    config = Application.get_env(
      :crawly,
      Crawly.Pipelines.FileStoragePipeline,
      Keyword.new()
    )
    folder = Keyword.get(config, :folder, "/tmp")
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


  #Performs the write operation
  @spec write(io, item) :: :ok when
          io: File.io_device(),
          item: any()
  defp write(io, item) do
    try do
      IO.write(io, item)
      IO.write(io, "\n")
    catch
      error, reason ->
        stacktrace = :erlang.get_stacktrace()

        Logger.error(
          "Could not write item: #{inspect(error)}, reason: #{
            inspect(reason)
          }, stacktrace: #{
            inspect(stacktrace)
          }
          "
        )
    end
  end
end
