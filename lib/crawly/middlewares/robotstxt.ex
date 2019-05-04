defmodule Crawly.Middlewares.RobotsTxt do
  require Logger

  def run(request, state) do
    case Gollum.crawlable?("Crawly", request.url) do
      :uncrawlable ->
        Logger.info("Url: #{request.url} is disabled by robots.txt")
        {false, state}

      _ ->
        {request, state}

    end
  end
end
