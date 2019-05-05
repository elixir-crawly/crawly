defmodule Crawly.Utils do
  require Logger

  def request_from_url(url) do
    %Crawly.Request{url: url, headers: []}
  end

  def pipe([], item, state), do: {item, state}
  def pipe(_, false, state), do: {false, state}

  def pipe([pipeline | pipelines], item, state) do
    {new_item, new_state} =
      try do
        {new_item, new_state} = pipeline.run(item, state)
      catch
        error, reason ->
          Logger.error(
            "Pipeline crash: #{pipeline}, error: #{inspect(error)}, reason: #{
              inspect(reason)
            }"
          )

          {item, state}
      end

    pipe(pipelines, new_item, new_state)
  end
end
