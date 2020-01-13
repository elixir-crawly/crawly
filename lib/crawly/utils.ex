defmodule Crawly.Utils do
  @moduledoc ~S"""
  Utility functions for Crawly
  """
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

  The state variable is used to persist the information accross multiple items.

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
          Logger.error(
            "Pipeline crash: #{module}, error: #{inspect(error)}, reason: #{
              inspect(reason)
            }, args: #{inspect(args)}"
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
end
