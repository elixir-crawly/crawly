defmodule Pipelines.PreviewTest do
  use ExUnit.Case, async: false

  @item %{first: "some", second: "data"}
  @state %{spider_name: Test, crawl_id: "test"}

  test "Preview items are stored in state" do
    pipelines = [{Crawly.Pipelines.Experimental.Preview}]

    {item, state} = Crawly.Utils.pipe(pipelines, @item, @state)

    assert assert item == @item

    preview = Map.get(state, :"Elixir.Crawly.Pipelines.Experimental.Preview")
    assert [@item] == preview
  end

  test "It's possible to resrtict number of stored items" do
    pipelines = [{Crawly.Pipelines.Experimental.Preview, limit: 2}]

    # Checking what happens if we try to store 3 items
    {_item, state0} = Crawly.Utils.pipe(pipelines, @item, @state)
    {_item, state1} = Crawly.Utils.pipe(pipelines, @item, state0)
    {_item, state2} = Crawly.Utils.pipe(pipelines, @item, state1)

    preview = Map.get(state2, :"Elixir.Crawly.Pipelines.Experimental.Preview")
    assert Enum.count(preview) == 2
  end
end
