defmodule Crawly.DataStorage.FileStorageBackend do
  @moduledoc """
  Implements Crawly.DataStorage.StorageBackend behaviour
  """
  @behaviour Crawly.DataStorage.StorageBackend
  require Logger

  @doc """
  Opens a file in a delayed_write mode (so writing is not going to be blocking)
  and returns {:ok, io_device()} as a result.
  """
  @spec init(spider_name) :: {:ok, File.io_device()} when
          spider_name: atom()
  def init(spider_name) do
    config = Application.get_env(
      :crawly,
      Crawly.DataStorage.FileStorageBackend,
      Keyword.new()
    )

    folder = Keyword.get(config, :folder, "/tmp")
    extension = Keyword.get(config, :extension, "txt")

    filename = "#{inspect(spider_name)}.#{extension}"
    full_path = Path.join([folder, filename])

    # Open file descriptor to write items
    {:ok, io_device} =
      File.open(
        full_path,
        [
          :binary,
          :write,
          :delayed_write,
          :utf8
        ]
      )

    # Include headers into the output. For now the headers are taken from item
    # description.
    case Keyword.get(config, :include_headers, false) do
      false ->
        :ok

      true ->
        headers = Enum.map(
          Application.get_env(:crawly, :item),
          &Atom.to_string/1
        )
        converted_headers = Crawly.Utils.list_to_csv(
          headers,
          :maps.from_list(Enum.zip(headers, headers))
        )
        :ok = write(io_device, converted_headers)
    end
    {:ok, io_device}
  end

  @doc """
  Implements the write callback for storage backend
  """
  @spec write(io, item) :: :ok when
          io: File.io_device(),
          item: any()
  def write(io, item) do
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

  @doc """
  Closes the io_device
  """
  @spec close(io) :: :ok
        when io: File.io_device()
  def close(io), do: File.close(io)
end
