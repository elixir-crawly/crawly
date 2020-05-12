defmodule Crawly.Pipelines.Experimental.SendToUI do
  @moduledoc """
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state, opts \\ []) do
    job_tag = Map.get(state, :job_tag, UUID.uuid1())
    spider_name = state.spider_name |> Atom.to_string()

    case Keyword.get(opts, :ui_node) do
      nil ->
        Logger.debug(
          "No ui node is set. It's required to set a UI node to use " <>
            "this pipeline. Ignoring the pipeline."
        )

      ui_node ->
        :rpc.cast(ui_node, CrawlyUI, :store_item, [
          spider_name,
          item, 
          job_tag,
          Node.self() |> to_string()
        ])
    end

    {item, Map.put(state, :job_tag, job_tag)}
  end
end
