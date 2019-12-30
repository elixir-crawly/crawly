defmodule Crawly.Worker do
  @moduledoc """
  A worker process responsible for the actual work (fetching requests,
  processing responces)
  """
  use GenServer

  require Logger

  # define the default worker fetch interval.
  @default_backoff 300

  defstruct backoff: @default_backoff, spider_name: nil

  def start_link([spider_name]) do
    GenServer.start_link(__MODULE__, [spider_name])
  end

  def init([spider_name]) do
    Process.send_after(self(), :work, @default_backoff)

    {:ok, %Crawly.Worker{spider_name: spider_name, backoff: @default_backoff}}
  end

  def handle_info(:work, state) do
    %{spider_name: spider_name, backoff: backoff} = state

    # Get a request from requests storage.
    new_backoff =
      case Crawly.RequestsStorage.pop(spider_name) do
        nil ->
          # Slow down a bit when there are no new URLs
          backoff * 2

        request ->
          # Process the request using following group of functions
          functions = [
            {:get_response, &get_response/1},
            {:parse_item, &parse_item/1},
            {:process_parsed_item, &process_parsed_item/1}
          ]

          case :epipe.run(functions, {request, spider_name}) do
            {:error, _step, reason, _step_state} ->
              # TODO: Add retry logic
              Logger.error(
                fn ->
                  "Crawly worker could not process the request to #{
                    inspect(request.url)
                  }
                  reason: #{inspect(reason)}"
                end
              )

              @default_backoff

            {:ok, _result} ->
              @default_backoff
          end
      end

    Process.send_after(self(), :work, new_backoff)

    {:noreply, %{state | backoff: new_backoff}}
  end

  @spec get_response({request, spider_name}) :: result
        when request: Crawly.Request.t(),
             spider_name: atom(),
             response: HTTPoison.Response.t(),
             result: {:ok, response, spider_name} | {:error, term()}
  defp get_response({request, spider_name}) do
    # check if spider-level fetcher is set. Overrides the globally configured fetcher.
    # if not set, log warning for explicit config preferred,
    # get the globally-configured fetcher. Defaults to HTTPoisonFetcher
    {fetcher, options} = Application.get_env(
      :crawly,
      :fetcher,
      {Crawly.Fetchers.HTTPoisonFetcher, []}
    )

    case fetcher.fetch(request, options) do
      {:ok, response} ->
        {:ok, {response, spider_name}}

      {:error, _reason} = response ->
        response
    end
  end

  @spec parse_item({response, spider_name}) :: result
        when response: HTTPoison.Response.t(),
             spider_name: atom(),
             response: HTTPoison.Response.t(),
             parsed_item: Crawly.ParsedItem.t(),
             next: {parsed_item, response, spider_name},
             result: {:ok, next} | {:error, term()}
  defp parse_item({response, spider_name}) do
    try do
      parsed_item = spider_name.parse_item(response)
      {:ok, {parsed_item, response, spider_name}}
    catch
      error, reason ->
        stacktrace = :erlang.get_stacktrace()

        Logger.error(
          "Could not parse item, error: #{inspect(error)}, reason: #{
            inspect(reason)
          }, stacktrace: #{inspect(stacktrace)}
          "
        )

        {:error, reason}
    end
  end

  @spec process_parsed_item({parsed_item, response, spider_name}) :: result
        when spider_name: atom(),
             response: HTTPoison.Response.t(),
             parsed_item: Crawly.ParsedItem.t(),
             result: {:ok, :done}
  defp process_parsed_item({parsed_item, response, spider_name}) do
    requests = Map.get(parsed_item, :requests, [])
    items = Map.get(parsed_item, :items, [])

    # Reading HTTP client options
    options = [Application.get_env(:crawly, :follow_redirect, false)]

    options =
      case Application.get_env(:crawly, :proxy, false) do
        false ->
          options

        proxy ->
          options ++ [{:proxy, proxy}]
      end

    # Process all requests one by one
    Enum.each(
      requests,
      fn request ->
        request =
          request
          |> Map.put(:prev_response, response)
          |> Map.put(:options, options)

        Crawly.RequestsStorage.store(spider_name, request)
      end
    )

    # Process all items one by one
    Enum.each(
      items,
      fn item ->
        Crawly.DataStorage.store(spider_name, item)
      end
    )

    {:ok, :done}
  end
end
