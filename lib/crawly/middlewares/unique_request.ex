defmodule Crawly.Middlewares.UniqueRequest do
  @moduledoc """
  Avoid scheduling requests for the same pages.
  """
  require Logger

  def run(request, state) do
    unique_request_seen_requests = Map.get(state, :unique_request_seen_requests, %{})

    url_without_fragment =
      request.url |> URI.parse() |> Map.put(:fragment, nil) |> URI.to_string()

    case Map.get(unique_request_seen_requests, url_without_fragment) do
      nil ->
        unique_request_seen_requests =
          Map.put(unique_request_seen_requests, url_without_fragment, true)

        new_state =
          Map.put(
            state,
            :unique_request_seen_requests,
            unique_request_seen_requests
          )

        {request, new_state}

      _ ->
        Logger.debug(
          "Dropping request: #{request.url}, as it's already processed (#{url_without_fragment})"
        )

        {false, state}
    end
  end
end
