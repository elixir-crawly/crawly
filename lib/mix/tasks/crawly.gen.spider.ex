defmodule Mix.Tasks.Crawly.Gen.Spider do
  @moduledoc """
  Generate Crawly spider template

  Reduce a bit of the boilerplate by providing spider generator function

    The generator function is used to generate a spider template for a given website.

    --filepath - specify a filepath where the spider is supposed to be generated (required)
    --spidername - specify a name of the spider module (required)
    --help - show this message
  """
  @shortdoc "Generate Crawly Spider template"

  use Mix.Task

  @impl Mix.Task
  @spec run([binary]) :: binary()
  def run(args \\ []) do
    args
    |> parse_args()
    |> response()
  end

  defp response({:error, message}) do
    Mix.shell().error("#{inspect(message)}")
    help()
  end

  defp response({opts, _word}) do
    cond do
      opts[:help] != nil ->
        help()

      true ->
        Map.new(opts) |> generate_spider()
    end
  end

  defp generate_spider(%{filepath: filepath, spidername: spidername}) do
    case File.exists?(filepath) do
      true ->
        Mix.shell().error("The spider already exists. Choose another filename")

      false ->
        path = Path.join(:code.priv_dir(:crawly), "./spider_template.ex")
        {:ok, spider_template} = File.read(path)

        spider_template =
          String.replace(spider_template, "SpiderTemplate", spidername)

        write_file(filepath, spider_template)
    end
  end

  # If filepath or spidername is missing
  defp generate_spider(_) do
    Mix.shell().error("Missing required arguments. \n")
    help()
  end

  defp parse_args(args) do
    {opts, word, errors} =
      OptionParser.parse(
        args,
        strict: [filepath: :string, spidername: :string, help: :boolean]
      )

    case errors do
      [] ->
        {opts, List.to_string(word)}

      errors ->
        {:error, "Unkown opions: #{inspect(errors)}"}
    end
  end

  defp write_file(filepath, spider_template) do
    case File.write(filepath, spider_template) do
      :ok ->
        Mix.shell().info("Done!")

      {:error, :enoent} ->
        Mix.shell().error(
          "Error writing file: directory in the filepath doesn't exist"
        )

      {:error, :enotdir} ->
        Mix.shell().error(
          "Error writing file: directory in the filepath doesn't exist"
        )

      {:error, :enospc} ->
        Mix.shell().error("Error writing file: no space left on the device")

      {:error, :eacces} ->
        Mix.shell().error("Error writing file: permission denied")
    end
  end

  defp help() do
    Mix.shell().info("""

    The generator function is used to generate a spider template for a given website.

    --filepath (required) - specify a path for a new file. If file already exists - exit with error
    --spidername (required) - specify a name of the spider module
    --help - show this message

    """)
  end
end
