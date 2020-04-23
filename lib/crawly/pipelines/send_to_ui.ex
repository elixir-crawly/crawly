defmodule Crawly.Pipelines.SendToUI do
  @moduledoc """
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state, opts \\ []) do
    job_tag =
      case Map.get(state, :job_tag, nil) do
        nil ->
          UUID.uuid1()
        tag ->
          tag
      end

    ui_node = Keyword.get(opts, :ui_node)
    spider_name = state.spider_name |> Atom.to_string()
    :rpc.cast(ui_node, CrawlyUI, :store_item, [spider_name, item, job_tag, Node.self() |> to_string()])
    {item, Map.put(state, :job_tag, job_tag)}
  end
end
