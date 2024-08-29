defmodule Crawly.SimpleStorage do
  @moduledoc false

  @dets_table :dets_simple_storage

  require Logger

  @typep table() :: atom()
  @typep key() :: term()
  @typep value() :: term()

  @doc """
  Initialize storage to store spiders information
  """
  @spec init :: {:error, any} | {:ok, any}
  def init() do
    Logger.debug("Opening/checking dynamic spiders storage")
    :dets.open_file(@dets_table, type: :set)
  end

  @doc """
  Insert a given object in a term storage

  iex(1)> Crawly.SimpleStorage.put(:spiders, Test, "12345")
  :ok
  """
  @spec put(table(), key(), value()) :: :ok | {:error, term()}
  def put(table_name, key, value) do
    :dets.insert(@dets_table, {{table_name, key}, value})
  end

  @doc """
  Return value for the given key from the term storage.

  iex(1)> Crawly.SimpleStorage.get(:spiders, Test)
  {:ok, "12345"}

  iex(1)> Crawly.SimpleStorage.get(:spiders, T)
  {:error, :not_found}
  """
  @spec get(table(), key()) ::
          {:ok, value()} | {:error, :not_found} | {:error, term()}
  def get(table, key) do
    case :dets.lookup(@dets_table, {table, key}) do
      {:error, _error} = err -> err
      [] -> {:error, :not_found}
      [{{^table, ^key}, value}] -> {:ok, value}
      _other -> {:error, :not_found}
    end
  end

  @doc """
  Makes a simple list from the simple storage.

  iex(17)> Crawly.SimpleStorage.list(:spiders)
  [Test4, Test3, Test2, Test1, Test]
  """
  @spec list(table()) :: [key()] | {:error, term()}
  def list(table) do
    first = :dets.first(@dets_table)
    list(table, first, [])
  end

  @doc """
  Deletes a given object

  iex(17)> Crawly.SimpleStorage.delete(:siders, Test1)
  :ok
  """
  @spec delete(table(), key()) :: :ok | {:error, term()}
  def delete(table, key) do
    :dets.delete(@dets_table, {table, key})
  end

  @doc """
  Deletes all objects from the storage

  iex(17)> Crawly.SimpleStorage.clear()
  :ok
  """
  @spec clear() :: :ok | {:error, term()}
  def clear(), do: :dets.delete_all_objects(@dets_table)

  defp list(_table, :"$end_of_table", acc), do: acc

  defp list(table, {table, key} = current_element, acc) do
    next = :dets.next(@dets_table, current_element)
    list(table, next, [key | acc])
  end

  defp list(table, current_element, acc) do
    next = :dets.next(@dets_table, current_element)
    list(table, next, acc)
  end
end
