defmodule Crawly.Middlewares.RobotsTxt do
  @moduledoc """
  Obey robots.txt

  A robots.txt file tells search engine crawlers which pages or files the
  crawler can or can't request from your site. This is used mainly to avoid
  overloading a site with requests!

  Please NOTE:
  The first rule of web crawling is you do not harm the website.
  The second rule of web crawling is you do NOT harm the website
  """

  @behaviour Crawly.Pipeline
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
