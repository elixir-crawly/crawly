defmodule Crawldis.Jobber.CrawlJob do
  @moduledoc """
  A crawl job, with all configuration required for requestors/processors.
  """
  @typep url :: String.t() | binary()
  @type t :: %__MODULE__{
    id: String.t(),
    start_urls: [url()]
  }
  @derive Jason.Encoder
  defstruct id: nil,
          start_urls: []
end
