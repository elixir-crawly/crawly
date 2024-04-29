defmodule Crawly.Middlewares.UniqueRequest do
  @moduledoc """
  Avoid scheduling multiple requests for the same page. Allow to set a hashing
  algorithm via options to reduce the memory footprint. Be aware of reduced collision
  resistance, depending on the chosen algorithm.

  ### Example Declarations
  ```
  middlewares: [
    Crawly.Middlewares.UniqueRequest
  ]
  ```

  ```
  middlewares: [
    {Crawly.Middlewares.UniqueRequest, hash: :sha}
  ]
  ```

  ```
  middlewares: [
    {Crawly.Middlewares.UniqueRequest, hash: :sha, normalise_url: fn url -> String.trim_trailing("/") end}
  ]
  ```

  See the [Erlang documentation for crypto](https://www.erlang.org/doc/man/crypto.html#type-sha1)
  for available algorithms.
  """
  require Logger

  def run(request, state, opts \\ []) do
    unique_request_seen_requests =
      Map.get(state, :unique_request_seen_requests, %{})

    normalised_url =
      case opts[:normalise_url] do
        nil ->
          # Assuming that trailing slashes do not affect the content.
          request.url |> String.trim_trailing("/")

        normalise_url when is_function(normalise_url, 1) ->
          normalise_url.(request.url)

        _ ->
          raise ArgumentError, "normalise_url must be a function with arity 1"
      end

    # optionally hash the URL
    unique_hash =
      case opts[:hash] do
        nil -> normalised_url
        algo -> :crypto.hash(algo, normalised_url)
      end

    case Map.get(unique_request_seen_requests, unique_hash) do
      nil ->
        unique_request_seen_requests =
          Map.put(unique_request_seen_requests, unique_hash, true)

        new_state =
          Map.put(
            state,
            :unique_request_seen_requests,
            unique_request_seen_requests
          )

        {request, new_state}

      _ ->
        Logger.debug(
          "Dropping request: #{request.url}, as it's already processed"
        )

        {false, state}
    end
  end
end
