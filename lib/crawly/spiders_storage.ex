defmodule Crawly.SpidersStorage do
  @moduledoc """
    Module for storing spider information using the `:dets` storage mechanism.

    This module provides functionality for storing and retrieving
    spider information in a term storage.

    The `:dets` module is used to store the information in a disk-based table.
    Functions:
    - `init/0`: Initializes the storage to store spider information.
    - `put/2`: Inserts the given spider name and YAML configuration into the storage.
    - `get/1`: Retrieves the YAML configuration for the given spider name.
    - `list/0`: Returns a list of all spider names stored in the storage.
    - `delete/1`: Deletes the YAML configuration for the given spider name.
    - `clear/0`: Deletes all spider information from the storage.
  """
  @dets_table :dets_spiders_storage

  require Logger

  @typep spider_name() :: binary() | module()
  @typep spider_yml() :: binary()

  @doc """
  Initialize storage to store spiders information
  """
  @spec init :: {:error, any} | {:ok, any}
  def init() do
    Logger.info("Opening/checking dynamic spiders storage")
    :dets.open_file(@dets_table, type: :set)
  end

  @doc """
  Insert a given object in a term storage

  iex(1)> Crawly.SpidersStorage.put(Test, "12345")
  :ok
  """
  @spec put(spider_name(), spider_yml()) :: :ok | {:error, term()}
  def put(spider_name, spider_yml) do
    :dets.insert(@dets_table, {spider_name, spider_yml})
  end

  @doc """
  Return value for the given key from the term storage.

  iex(1)> Crawly.SpidersStorage.get(Test)
  {:ok, "12345"}

  iex(1)> Crawly.SpidersStorage.get(T)
  {:error, :not_found}
  """
  @spec get(spider_name()) ::
          {:ok, spider_yml()} | {:error, :not_found} | {:error, term()}
  def get(spider_name) do
    case :dets.lookup(@dets_table, spider_name) do
      {:error, _error} = err -> err
      [] -> {:error, :not_found}
      [{^spider_name, spider_yml}] -> {:ok, spider_yml}
    end
  end

  @doc """
  Makes a simple list from the spiders storage.

  iex(17)> Crawly.SpidersStorage.list()
  [Test4, Test3, Test2, Test1, Test]
  """
  @spec list() :: [spider_name()] | {:error, term()}
  def list() do
    first = :dets.first(@dets_table)
    list(first, [])
  end

  @doc """
  Deletes a given object

  iex(17)> Crawly.SpidersStorage.delete(Test1)
  :ok
  """
  @spec delete(spider_name()) :: :ok | {:error, term()}
  def delete(spider_name) do
    :dets.delete(@dets_table, spider_name)
  end

  @doc """
  Deletes all objects from the storage

  iex(17)> Crawly.SpidersStorage.clear()
  :ok
  """
  @spec clear() :: :ok | {:error, term()}
  def clear(), do: :dets.delete_all_objects(@dets_table)

  defp list(:"$end_of_table", acc), do: acc

  defp list(current_element, acc) do
    next = :dets.next(@dets_table, current_element)
    list(next, [current_element | acc])
  end
end
