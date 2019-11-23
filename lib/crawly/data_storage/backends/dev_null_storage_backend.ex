defmodule Crawly.DataStorage.DevNullStorageBackend do
  @moduledoc """
  Implements Crawly.DataStorage.StorageBackend behaviour, which does not actually
  store any item
  """
  @behaviour Crawly.DataStorage.StorageBackend

  require Logger

  @spec init(spider_name) :: {:ok, :null} when
          spider_name: atom()
  def init(_spider_name) do
    {:ok, :null}
  end

  @doc """
  Implements a write callback which just ignores item
  """
  @spec write(io, item) :: :ok when
          io: atom(),
          item: any()
  def write(_io, _item), do: :ok

  @doc """
  Closes the io_device
  """
  @spec close(atom()) :: :ok
  def close(:null), do: :ok
end
