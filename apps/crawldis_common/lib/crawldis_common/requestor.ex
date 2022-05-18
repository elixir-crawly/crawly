defmodule CrawldisCommon.Requestor do
  defstruct id: nil
  alias CrawldisCommon.Requestor
  @behaviour CrawldisCommon.Worker

  use Supervisor, restart: :transient

  @impl true
  def start_link(id) do
    Supervisor.start_link(__MODULE__, [], name: via(id))
  end

  @impl true
  def init(_init_arg) do
    children = [
      # add in request queue
      Requestor.Worker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @impl CrawldisCommon.Worker
  def via(id) do
    {:via, Horde.Registry, {CrawldisCommon.Cluster.RequestorRegistry, id}}
  end

  @impl CrawldisCommon.Worker
  def stop(id), do: Supervisor.stop(via(id))



  @spec new_request(map()) :: %Crawly.Request{}
  def new_request(attrs \\ %{}) do
    %Crawly.Request{
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
