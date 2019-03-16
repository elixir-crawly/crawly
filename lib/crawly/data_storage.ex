defmodule Crawly.DataStorage do
  @moduledoc """
  URLS Storage, a module responsible for storing urls for crawling
  """

  @doc """
  Storing URL

  ## Examples

      iex> Crawly.URLStorage.store_item
      :ok

  """
  require Logger

  use GenServer

  def store_item(url) do
    Logger.info("Stored item is: #{inspect(url)}")
  end

  def start_link([]) do
    Logger.info("Starting data storage")

    GenServer.start_link(__MODULE__, [], name: :data_storage)
  end

  def init(_args) do
    {:ok, %{}}
  end
end
