defmodule Crawly.Middlewares.RobotsTxt do
  require Logger

  def run(request, state) do
    case Gollum.crawlable?("Crawly", request.url) do
      :uncrawlable ->
        Logger.debug(
          "Dropping request: #{request.url} (robots.txt filter)"
        )

        {false, state}

      _ ->
        {request, state}
    end
  end
end
