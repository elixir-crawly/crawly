defmodule CrawldisCommon.Utils do

  @moduledoc false
  alias CrawldisCommon.Jobber.CrawlJob
  @spec new_request(%CrawlJob{}, String.t(), map()) :: %Crawly.Request{}
  def new_request(%CrawlJob{id: crawl_job_id}, url, attrs \\ %{}) do
    %Crawly.Request{
      id: UUID.uuid4(),
      crawl_job_id: crawl_job_id,
      url: url,
      fetcher: Crawly.Fetchers.HTTPoisonFetcher
    }
    |> Map.merge(attrs)
  end

  @doc """
  Derive a new request from a prior request, used to shallow clone a request and then overwrite certain attributes
  """
  @spec derive_request(%Crawly.Request{}, map()) :: %Crawly.Request{}
  def derive_request(request, attrs \\ %{}) do
    request
    |> Map.take([:headers, :extractors, :fetcher])
    |> Map.merge(attrs)
  end
end
