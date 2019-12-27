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

  - `:folder`, optional. The folder in which the file will be created. Defaults to system temp folder.
  - `:extension`, optional. The file extension in which the file will be created with. Defaults to `jl`.

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
          opts :: [folder: String.t(), extension: String.t()]
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
    opts = Enum.into(opts, %{folder: nil, extension: nil})

    global_config =
      Application.get_env(
        :crawly,
        Crawly.Pipelines.WriteToFile,
        Keyword.new()
      )

    folder =
      Map.get(opts, :folder) ||
        Keyword.get(global_config, :folder, System.tmp_dir!())

    extension =
      Map.get(opts, :extension) ||
        Keyword.get(global_config, :extension, "jl")

    fd = open_fd(state.spider_name, folder, extension)
    :ok = write(fd, item)
    {item, Map.put(state, :write_to_file_fd, fd)}
  end

  defp open_fd(spider_name, folder, extension) do
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
