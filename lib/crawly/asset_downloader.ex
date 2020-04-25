defmodule Crawly.AssetDownloader do
  require Logger

  use GenServer

  def start_link([]) do
    Logger.debug("Starting asset downloader")

    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  def download_asset(directory, url) do
    GenServer.cast(__MODULE__, {:download_asset, directory, url})
  end

  @impl true
  def handle_cast({:download_asset, directory, url}, state) do
    :ok = File.mkdir_p(directory)

    case HTTPoison.get(url) do
      {:ok, response} ->
        full_path = Path.join(directory, file_name(url))
        :ok = File.write(full_path, response.body)
        Logger.debug("Downloaded image from URL #{url} into #{full_path}")
      {:error, error} ->
        Logger.error("Could not download image from URL #{url}: #{inspect(error)}")
    end

    {:noreply, state}
  end

  # Returns the string after the last slash, e.g.:
  # https://amazon.com/products/picture.jpg => picture.jpg
  # It is usually a good approximation of a "file name" on the web
  defp file_name(url) do
    Regex.run(~r/(?<=\/)[^\/]+$/, url)
    |> List.first()
  end
end
