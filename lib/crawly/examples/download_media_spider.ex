defmodule Crawly.Examples.DownloadMediaSpider do
   use Crawly.Spider
  require Logger

   @impl Crawly.Spider
   def base_url(), do: "https://www.homebase.co.uk"

   @impl Crawly.Spider
   def init() do
     [
       start_urls: [
         "https://www.homebase.co.uk/our-range/lighting-and-electrical/lighting/torches-and-nightlights/worklights"
       ]
     ]
   end

   @impl Crawly.Spider
   def parse_item(response) do
     {:ok, document} = Floki.parse_document(response.body)

     # Extract product categories URLs
     product_categories =
       document
       |> Floki.find("div.product-list-footer a")
       |> Floki.attribute("href")

     # Extract individual product page URLs
     product_pages =
       document
       |> Floki.find("a.product-tile")
       |> Floki.attribute("href")

     urls = product_pages ++ product_categories

     # Convert URLs into Requests
     requests =
       urls
       |> Enum.uniq()
       |> Enum.map(&build_absolute_url/1)
       |> Enum.map(&Crawly.Utils.request_from_url/1)

     # category =
     #   document
     #   |> Floki.find(".breadcrumb span")
     #   |> Enum.at(1)
     #   |> Floki.text()

     images = document |> Floki.find("img.rsTmb") |> Floki.attribute("src")

     items =
       images
       |> Enum.map(fn image_url -> %{"image_url" => image_url} end)

     %Crawly.ParsedItem{:items => items, :requests => requests}
   end

   @impl Crawly.Spider
   def override_settings() do
     [
       pipelines: [
         {Crawly.Pipelines.DownloadMedia, field: "image_url", directory: "/tmp/crawly/homebase"},
         Crawly.Pipelines.JSONEncoder,
         {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "json"},
       ]

     ]
   end

   defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
