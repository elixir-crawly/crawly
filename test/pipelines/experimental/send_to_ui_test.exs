defmodule Pipelines.Experimental.SendToUITest do
  use ExUnit.Case, async: false

  @item %{title: "Title", author: "Me"}
  test "job tag is added to the state" do
    pipelines = [
      {Crawly.Pipelines.Experimental.SendToUI, ui_node: :"ui@127.0.0.1"}
    ]

    state = %{spider_name: PipelineTestSpider}
    {@item, state} = Crawly.Utils.pipe(pipelines, @item, state)

    assert Map.get(state, :job_tag) != nil
  end

  test "job tag is not re-generated if pipeline was re-executed" do
    pipelines = [
      {Crawly.Pipelines.Experimental.SendToUI, ui_node: :"ui@127.0.0.1"}
    ]

    state = %{spider_name: PipelineTestSpider}
    {@item, state} = Crawly.Utils.pipe(pipelines, @item, state)

    job_tag = Map.get(state, :job_tag)

    {@item, state2} = Crawly.Utils.pipe(pipelines, @item, state)

    assert Map.get(state2, :job_tag) == job_tag
  end
end
