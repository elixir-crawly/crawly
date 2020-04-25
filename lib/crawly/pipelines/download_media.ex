defmodule Crawly.Pipelines.DownloadMedia do
  alias Crawly.AssetDownloader

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
            AssetDownloader.download_asset(opts[:directory], image_url)
            {item, state}
        end
    end
  end
end
