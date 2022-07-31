defmodule Crawldis.Utils do

  @moduledoc false
  alias Crawldis.Jobber.CrawlJob
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

  @doc "Returns the panel configuration"
  @type panel_config :: %{api_key: String.t, endpoint: String.t}
  @spec get_panel_config! :: panel_config()
  def get_panel_config! do
    config = Application.get_env(:crawldis, :panel)
    if is_nil config do
      raise "Panel config not set"
    end
    config |> Enum.into(%{})
  end

  @doc "String representation of node name"
  @spec self :: String.t
  def self do
    Node.self() |> Atom.to_string()
  end
end
