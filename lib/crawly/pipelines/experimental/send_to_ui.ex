defmodule Crawly.Pipelines.Experimental.SendToUI do
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

    ui_node =
      case Keyword.get(opts, :ui_node) do
        nil ->
          throw(
            "No ui node is set. It's required to set a UI node to use " <>
              "this pipeline"
          )

        node ->
          node
      end

    spider_name = state.spider_name |> Atom.to_string()

    :rpc.cast(ui_node, CrawlyUI, :store_item, [
      spider_name,
      item,
      job_tag,
      Node.self() |> to_string()
    ])

    {item, Map.put(state, :job_tag, job_tag)}
  end
end
