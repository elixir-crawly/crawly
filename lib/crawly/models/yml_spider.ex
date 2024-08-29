defmodule Crawly.Models.YMLSpider do
  @moduledoc false

  @table_name __MODULE__

  @doc """
  Stores the YAML binary data for a spider configuration in a persistent storage backend.

  Arguments:
  - `spider_name`: The name of the spider configuration to store. This can be any Erlang term.
  - `yml_binary`: A binary string containing the YAML data for the spider configuration.

  Returns:
  - `:ok` if the storage operation was successful.
  - `{:error, reason}` if the storage operation failed for some reason. `reason` can be any term.

  Example usage:
  Crawly.Models.YMLSpider.new(Books, "YML spider code")
  """
  @spec new(spider_name, yml_binary) :: :ok | {:error, term()}
        when spider_name: term(),
             yml_binary: String.t()
  def new(spider_name, yml_binary) do
    Crawly.SimpleStorage.put(@table_name, spider_name, yml_binary)
  end

  @doc """
  Get spider YML from the storage

  Arguments:
  - `spider_name`: The name of the spider configuration to store. This can be any Erlang term.

  Returns:
  - `{:ok, spider_yml}` if the storage operation was successful.
  - `{:error, reason}` if the storage operation failed for some reason. `reason` can be any term.

  Example usage:
  > Crawly.Models.YMLSpider.get(Books)
  """

  @spec get(term()) :: {:error, term()} | {:ok, String.t()}
  def get(spider_name), do: Crawly.SimpleStorage.get(@table_name, spider_name)

  @doc """
  Deletes a given spider from the SimpleStorage
  """
  @spec delete(term()) :: {:error, term()} | :ok
  def delete(spider_name),
    do: Crawly.SimpleStorage.delete(@table_name, spider_name)

  @doc """
  List all spiders in SimpleStorage
  """
  @spec list() :: [term()]
  def list(), do: Crawly.SimpleStorage.list(@table_name)

  @doc """
  Iterates through a list of spider configurations, loads them.
  """
  @spec load() :: :ok
  def load() do
    Enum.each(
      list(),
      fn spider ->
        {:ok, spider_yml} = get(spider)
        load(spider_yml)
      end
    )
  end

  @doc """
  Loads a YAML binary as Spider module

  Args:

  yml_binary: A binary representation of a YAML spider.

  Raises an error if there is a problem parsing the YAML document or evaluating the Elixir code template.
  Example:
  iex> yml_binary = "name: my_spider"
  iex> load(yml_binary)
  {:ok, %{name: "my_spider"}, []}
  """
  @spec load(binary()) :: {term(), Code.binding()}
  def load(yml_binary) do
    {:ok, yml_map} = YamlElixir.read_from_string(yml_binary)

    path =
      Path.join(
        :code.priv_dir(:crawly),
        "./yml_spider_template.eex"
      )

    template = EEx.eval_file(path, spider: yml_map)

    name = String.to_atom("Elixir." <> Map.get(yml_map, "name"))
    Crawly.Utils.register_spider(name)

    Code.eval_string(template)
  end
end
