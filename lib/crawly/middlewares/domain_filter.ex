defmodule Crawly.Middlewares.DomainFilter do
  require Logger

  def run(request, state) do
    base_url = state.spider_name.base_url()

    case String.contains?(request.url, base_url) do
      false ->
        Logger.info("Dropping unrelated request: #{inspect(request)}")
        {false, state}
      true ->
        Logger.info("Processing requst")
        {request, state}
    end
  end
end
