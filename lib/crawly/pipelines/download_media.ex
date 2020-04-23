defmodule Crawly.Pipelines.DownloadMedia do
  @moduledoc """
    TODO: documentation
  """
  @behaviour Crawly.Pipeline
  require Logger

  @impl Crawly.Pipeline
  @spec run(map, map, field: list(atom), directory: String.t()) ::
          {false, state :: map} | {csv_line :: String.t(), state :: map}
  def run(item, state, opts \\ []) do
    opts = Enum.into(opts, %{field: nil, directory: "/tmp"})
    case opts[:field] do
      nil ->
        Logger.error(
          "Dropping item: #{inspect(item)}. Reason: No field declared for DownloadMedia"
        )
        {false, state}

      field ->
        case Map.get(item, field) do
          nil ->
            Logger.error(
              "Dropping item: #{inspect(item)}. Reason: Item has no value for key #{inspect(field)}"
            )
            {false, state}

          image_url ->
            save_image(opts[:directory], image_url)
            {item, state}
        end
    end
  end

  defp save_image(directory, url) do
    :ok = File.mkdir_p(directory)

    case HTTPoison.get(url) do
      {:ok, response} ->
        full_path = Path.join(directory, file_name(url))
        :ok = File.write(full_path, response.body)
      {:error, error} ->
        Logger.error("Could not download image from URL #{url}: #{inspect(error)}")
    end
  end

  # Returns the string after the last slash, e.g.:
  # https://amazon.com/products/picture.jpg => picture.jpg
  # It is usually a good approximation of a "file name" on the web
  defp file_name(url) do
    Regex.run(~r/(?<=\/)[^\/]+$/, url)
    |> List.first()
  end
end
