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

  See the [Erlang documentation for crypto](https://www.erlang.org/doc/man/crypto.html#type-sha1)
  for available algorithms.
  """
  require Logger

  def run(request, state, opts \\ []) do
    unique_request_seen_requests =
      Map.get(state, :unique_request_seen_requests, %{})

    # we assume that https://example/foo and https://example/foo/ refer to the same content,
    # in case they are both accessible
    normalised_url = request.url |> String.replace_suffix("/", "")

    # optionally hash the URL
    unique_hash =
      if algo = opts[:hash] do
        :crypto.hash(algo, normalised_url)
      else
        normalised_url
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
