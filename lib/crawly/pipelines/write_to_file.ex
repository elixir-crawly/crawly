defmodule Crawly.Pipelines.WriteToFile do
  @moduledoc """
  Stores a given item into Filesystem

  Pipeline Lifecycle:
  1. When run (by `Crawly.Utils.pipe`), creates a file descriptor if not already created.
  2. Performs the write operation
  3. File descriptor is reused by passing it through the pipeline state with `:write_to_file_fd`

  > Note: `File.close` is not necessary due to the file descriptor being automatically closed upon the end of a the parent process.
  >
  > Refer to https://github.com/oltarasenko/crawly/pull/19#discussion_r350599526 for relevant discussion.

  ### Options
  In the absence of tuple-based options being passed, the pipeline will fallback onto the config of `:crawly`, `Crawly.Pipelines.WriteToFile`, for the `:folder` and `:extension` keys

  - `:folder`, optional. The folder in which the file will be created. Defaults to current project's folder.
     If provided folder does not exist it's created.
  - `:extension`, optional. The file extension in which the file will be created with. Defaults to `jl`.
  - `:include_timestamp`, boolean, optional, true by default. Allows to add timestamp to the filename.
  ### Example Declaration
  ```
  pipelines: [
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"}
  ]
  ```
  ### Example Output

  ```
  iex> item = %{my: "item"}
  iex> WriteToFile.run(item, %{}, folder: "/tmp", extension: "csv")
  { %{my: "item"} , %{write_to_file_fd: #PID<0.123.0>} }
  ```

  """

  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  @spec run(
          item :: any,
          state :: %{
            optional(:write_to_file_fd) => pid | {:file_descriptor, atom, any}
          },
          opts :: [
            folder: String.t(),
            extension: String.t(),
            include_timestamp: boolean()
          ]
        ) ::
          {item :: any,
           state :: %{write_to_file_fd: pid | {:file_descriptor, atom, any}}}
  def run(item, state, opts \\ [])

  def run(item, %{write_to_file_fd: fd} = state, _opts) do
    :ok = write(fd, item)
    {item, state}
  end

  # No active FD
  def run(item, state, opts) do
    opts =
      Enum.into(opts, %{folder: nil, extension: nil, include_timestamp: true})

    folder = Map.get(opts, :folder, "./")

    :ok = maybe_create_folder(folder)

    extension = Map.get(opts, :extension, "jl")

    filename =
      case Map.get(opts, :include_timestamp, false) do
        false ->
          "#{inspect(state.spider_name)}.#{extension}"

        true ->
          ts_string =
            NaiveDateTime.utc_now()
            |> NaiveDateTime.to_string()
            |> String.replace(~r/( |-|:|\.)/, "_")

          "#{inspect(state.spider_name)}_#{ts_string}.#{extension}"
      end

    fd = open_fd(folder, filename)
    :ok = write(fd, item)
    {item, Map.put(state, :write_to_file_fd, fd)}
  end

  defp open_fd(folder, filename) do
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

  # Creates a folder if it does not exist
  defp maybe_create_folder(path) do
    case File.exists?(path) do
      false ->
        File.mkdir_p(path)

      true ->
        :ok
    end
  end
end
