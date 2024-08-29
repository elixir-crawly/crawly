defmodule Crawly.Utils do
  @moduledoc ~S"""
  Utility functions for Crawly
  """

  @spider_storage_key :crawly_spiders

  require Logger

  @doc """
  A helper function which returns a Request structure for the given URL
  """
  @spec request_from_url(binary()) :: Crawly.Request.t()
  def request_from_url(url), do: Crawly.Request.new(url)

  @doc """
  A helper function which converts a list of URLS into a requests list.
  """
  @spec requests_from_urls([binary()]) :: [Crawly.Request.t()]
  def requests_from_urls(urls), do: Enum.map(urls, &request_from_url/1)

  @doc """
  A helper function which joins relative url with a base URL
  """
  @spec build_absolute_url(binary(), binary()) :: binary()
  def build_absolute_url(url, base_url) do
    URI.merge(base_url, url) |> to_string()
  end

  @doc """
  A helper function which joins relative url with a base URL for a list
  """
  @spec build_absolute_urls([binary()], binary()) :: [binary()]
  def build_absolute_urls(urls, base_url) do
    Enum.map(urls, fn url -> URI.merge(base_url, url) |> to_string() end)
  end

  @doc """
  Pipeline/Middleware helper

  Executes a given list of pipelines on the given item, mimics filtermap behavior.
  Takes an item and state and passes it through a list of modules which implements a pipeline behavior, executing the pipeline's `c:Crawly.Pipeline.run/3` function.

  The pipe function must either return a boolean (`false`), or an updated item.

  If `false` is returned by a pipeline, the item is dropped. It will not be processed by any descendant pipelines.

  In case of a pipeline crash, the pipeline will be skipped and the item will be passed on to descendant pipelines.

  The state variable is used to persist the information across multiple items.

  ### Usage in Tests

  The `Crawly.Utils.pipe/3` helper can be used in pipeline testing to simulate a set of middlewares/pipelines.

  Internally, this function is used for both middlewares and pipelines. Hence, you can use it for testing modules that implement the `Crawly.Pipeline` behaviour.

  For example, one can test that a given item is manipulated by a pipeline as so:
  ```elixir
  item = %{my: "item"}
  state = %{}
  pipelines = [ MyCustomPipelineOrMiddleware ]
  {new_item, new_state} = Crawly.Utils.pipe(pipelines, item, state)

  ```
  """
  @spec pipe(pipelines, item, state) :: result
        when pipelines: [Crawly.Pipeline.t()],
             item: map(),
             state: map(),
             result: {new_item | false, new_state},
             new_item: map(),
             new_state: map()
  def pipe([], item, state), do: {item, state}
  def pipe(_, false, state), do: {false, state}

  def pipe([pipeline | pipelines], item, state) do
    {module, args} =
      case pipeline do
        {module, args} ->
          {module, args}

        {module} ->
          {module, nil}

        module ->
          {module, nil}
      end

    {new_item, new_state} =
      try do
        case args do
          nil -> module.run(item, state)
          _ -> module.run(item, state, args)
        end
      catch
        error, reason ->
          call =
            case args do
              nil ->
                "#{inspect(module)}.run(#{inspect(item)}, #{inspect(state)})"

              _ ->
                "#{inspect(module)}.run(#{inspect(item)}, #{inspect(state)}, #{inspect(args)})"
            end

          Logger.error(
            "Pipeline crash by call: #{call}\n#{Exception.format(error, reason, __STACKTRACE__)}"
          )

          {item, state}
      end

    pipe(pipelines, new_item, new_state)
  end

  @doc """
  A wrapper over Process.send after
  This wrapper should be used instead of Process.send_after, so it's possible
  to mock the last one. To avoid race conditions on worker's testing.
  """
  @spec send_after(pid(), term(), pos_integer()) :: reference()
  def send_after(pid, message, timeout) do
    Process.send_after(pid, message, timeout)
  end

  @doc """
  A helper which allows to extract a given setting.

  Returned value is a result of intersection of the global settings and settings
  defined as settings_override inside the spider. Settings defined on spider are
  taking precedence over the global settings defined in the config.
  """
  @spec get_settings(setting_name, Crawly.spider(), default) :: result
        when setting_name: atom(),
             default: term(),
             result: term()

  def get_settings(setting_name, spider_name \\ nil, default \\ nil) do
    global_setting = Application.get_env(:crawly, setting_name, default)

    case get_spider_setting(setting_name, spider_name) do
      nil ->
        # No custom settings for a spider found
        global_setting

      custom_setting ->
        custom_setting
    end
  end

  @doc """
  Returns a list of known modules which implements Crawly.Spider behaviour
  """
  @spec list_spiders() :: [module()]
  def list_spiders() do
    modules = get_modules_from_applications() ++ registered_spiders()

    Enum.reduce(
      modules,
      [],
      fn mod, acc ->
        try do
          behaviors =
            Keyword.take(mod.module_info(:attributes), [:behaviour])
            |> Keyword.values()
            |> List.flatten()

          module_has_spider_behaviour =
            Enum.any?(behaviors, fn beh -> beh == Crawly.Spider end)

          case module_has_spider_behaviour do
            true ->
              [mod] ++ acc

            false ->
              acc
          end
        rescue
          error ->
            Logger.debug(
              "Could not classify module #{mod} as spider: #{inspect(error)}"
            )

            acc
        end
      end
    )
  end

  @doc """
  Loads spiders from a given directory. Store thm in persistant term under :spiders

  This allows to readup spiders stored in specific directory which is not a part
  of Crawly application
  """
  @spec load_spiders() :: {:ok, [module()]} | {:error, :no_spiders_dir}
  def load_spiders() do
    dir = System.get_env("SPIDERS_DIR", "./spiders")
    Logger.debug("Using the following folder to load extra spiders: #{dir}")

    {:ok, files} = File.ls(dir)

    Enum.each(
      files,
      fn file ->
        path = Path.join(dir, file)
        [{module, _binary}] = Code.compile_file(path)

        # Use persistent term to store information about loaded spiders
        register_spider(module)
      end
    )

    {:ok, registered_spiders()}
  end

  @doc """
  Register a given spider (so it's visible in the spiders list)
  """
  @spec register_spider(module()) :: :ok
  def register_spider(name) do
    known_spiders = :persistent_term.get(@spider_storage_key, [])
    :persistent_term.put(@spider_storage_key, Enum.uniq([name | known_spiders]))
  end

  @doc """
  Return a list of registered spiders
  """
  @spec registered_spiders() :: [module()]
  def registered_spiders(), do: :persistent_term.get(@spider_storage_key, [])

  @doc """
  Remove all previousely registered dynamic spiders
  """
  @spec clear_registered_spiders() :: :ok
  def clear_registered_spiders() do
    :persistent_term.put(@spider_storage_key, [])
  end

  @doc """
  A helper function that is used by YML spiders

  Extract requests from a given document using a given set of selectors
  builds absolute_urls.

  Selectors are aprovided as a JSON encoded list of maps, that contain
  selector and attribute keys. E.g.
  selectors = [%{"selector" => "a", "attribute" => "href"}]

  Base URL is required to build absolute url from extracted links
  """
  @spec extract_requests(document, selectors, base_url) :: requests
        when document: [Floki.html_node()],
             selectors: binary(),
             base_url: binary(),
             requests: [Crawly.Request.t()]
  def extract_requests(document, selectors, base_url) do
    selectors = Poison.decode!(selectors)

    Enum.reduce(
      selectors,
      [],
      fn %{"selector" => selector, "attribute" => attr}, acc ->
        links = document |> Floki.find(selector) |> Floki.attribute(attr)
        urls = Crawly.Utils.build_absolute_urls(links, base_url)
        requests = Crawly.Utils.requests_from_urls(urls)
        requests ++ acc
      end
    )
  end

  @doc """
  A helper function that is used by YML spiders

  Extract items (actually one item) from a given document using a
  given set of selectors.

  Selectors are aprovided as a JSON encoded list of maps, that contain
  name and selector binary keys. For example:

  field_selectors = [%{"selector" => "h1", "name" => "title"}]
  """
  @spec extract_items(document, field_selectors) :: items
        when document: [Floki.html_node()],
             field_selectors: binary(),
             items: [map()]
  def extract_items(document, field_selectors) do
    fields = Poison.decode!(field_selectors)

    item =
      Enum.reduce(
        fields,
        %{},
        fn %{"name" => name, "selector" => selector}, acc ->
          field_value = document |> Floki.find(selector) |> Floki.text()
          Map.put(acc, name, field_value)
        end
      )

    [item]
  end

  @doc """
  A helper function that allows to preview spider results based on a given YML
  """
  @spec preview(yml) :: [result]
        when yml: binary(),
             result:
               %{url: binary(), items: [map()], requests: [binary()]}
               | %{error: term()}
               | %{error: term(), url: binary()}
  def preview(yml) do
    case YamlElixir.read_from_string(yml) do
      {:error, parsing_error} ->
        [%{error: "#{inspect(parsing_error)}"}]

      {:ok,
       %{
         "start_urls" => start_urls,
         "base_url" => base_url,
         "fields" => fields,
         "links_to_follow" => links
       }} ->
        fields = Poison.encode!(fields)
        links = Poison.encode!(links)

        Enum.map(
          # Work only with 5 first URLs, so we don't timeout
          Enum.take(start_urls, 5),
          fn url ->
            fetch(url, base_url, fields, links)
          end
        )

      {:ok, _other} ->
        [%{error: "Nothing can be extracted from YML code"}]
    end
  end

  defp fetch(url, base_url, fields, links) do
    case HTTPoison.get(url) do
      {:error, reason} ->
        %{
          url: url,
          error: "#{inspect(reason)}"
        }

      {:ok, response} ->
        {:ok, document} = Floki.parse_document(response.body)

        extracted_urls =
          document
          |> Crawly.Utils.extract_requests(links, base_url)
          |> Enum.map(fn req -> req.url end)
          # restrict number of shown urls, so output is not too big
          |> Enum.take(10)

        %{
          url: url,
          items: Crawly.Utils.extract_items(document, fields),
          requests: extracted_urls
        }
    end
  end

  @doc """
    Composes the log file path for a given spider and crawl ID.

    Args:
    spider_name (atom): The name of the spider to create the log path for.
    crawl_id (string): The ID of the crawl to create the log path for.

    Returns:
    string: The file path to the log file for the given spider and crawl ID.

    Examples:
    iex> spider_log_path(:my_spider, "crawl_123")
    "/tmp/crawly/my_spider/crawl_123.log"

    iex> spider_log_path(:my_spider, "crawl_456")
    "/tmp/crawly/my_spider/crawl_456.log"
  """
  @spec spider_log_path(spider_name, crawl_id) :: path
        when spider_name: atom(),
             crawl_id: String.t(),
             path: String.t()
  def spider_log_path(spider_name, crawl_id) do
    spider_name_str =
      case Atom.to_string(spider_name) do
        "Elixir." <> name_str -> name_str
        name_str -> name_str
      end

    log_dir =
      Crawly.Utils.get_settings(
        :log_dir,
        spider_name,
        System.tmp_dir()
      )

    Path.join([
      log_dir,
      spider_name_str,
      crawl_id
    ]) <> ".log"
  end

  ##############################################################################
  # Private functions
  ##############################################################################
  @spec get_spider_setting(Crawly.spider(), setting_name) :: result
        when setting_name: atom(),
             result: nil | term()

  defp get_spider_setting(_setting_name, nil), do: nil

  defp get_spider_setting(setting_name, spider_name) do
    case function_exported?(spider_name, :override_settings, 0) do
      true ->
        Keyword.get(spider_name.override_settings(), setting_name, nil)

      false ->
        nil
    end
  end

  @spec get_modules_from_applications() :: [module()]
  def get_modules_from_applications do
    Enum.reduce(Application.started_applications(), [], fn {app, _descr, _vsn},
                                                           acc ->
      case :application.get_key(app, :modules) do
        {:ok, modules} ->
          modules ++ acc

        _other ->
          acc
      end
    end)
  end

  @doc """
  Wrapper function for Code.ensure_loaded?/1 to allow mocking
  """
  @spec ensure_loaded?(atom) :: boolean
  def ensure_loaded?(module) do
    Code.ensure_loaded?(module)
  end

  @doc """
  Function to get setting module in proper data structure
  """
  @spec unwrap_module_and_options(term) ::
          {atom, maybe_improper_list}
  def unwrap_module_and_options(setting) do
    case setting do
      {module, args} when is_list(args) and is_atom(module) ->
        {module, args}

      module when is_atom(module) ->
        {module, []}

      x ->
        raise "Invalid format: A #{setting} setting cannot be defined in the form `{#{inspect(x)}}`. Only the forms `{module, options}` and `module` are valid"
    end
  end

  @doc """
  Retrieves a header value from a list of key-value tuples or a map.

  This function searches for a header with the specified key in the given list
  of headers or map. If found, it returns the corresponding value; otherwise,
  it returns the provided default value if provided, otherwise `nil`.

  ## Parameters

  - `headers`: A list of key-value tuples or a map representing headers.
  - `key`: The key of the header to retrieve.
  - `default`: (Optional) The default value to return if the header is not found. If not provided, returns `nil`.

  ## Returns

  The value of the header if found, otherwise the default value if provided, otherwise `nil`.
  """
  @spec get_header(
          headers :: [{atom | binary, binary}] | %{binary => binary},
          key :: binary,
          default :: binary | nil
        ) :: binary | nil
  def get_header(headers, key, default \\ nil) do
    downcased_key = String.downcase(key, :ascii)

    Enum.find_value(headers, default, fn
      {k, v} when is_atom(k) ->
        if Atom.to_string(k) == downcased_key, do: v, else: nil

      {k, v} ->
        if String.downcase(k, :ascii) == downcased_key, do: v, else: nil

      _ ->
        nil
    end)
  end
end
