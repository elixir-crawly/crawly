defmodule Pipelines.DuplicatesFilterTest do
  use ExUnit.Case, async: false

  @valid %{data: [%{some: "nested_data"}], id: "my_id"}

  test "DuplicatesFilter prevents drops duplicate items with the same item_id value" do
    Application.put_env(:crawly, :item_id, :id)
    pipelines = [Crawly.Pipelines.DuplicatesFilter]
    item = @valid
    state = %{}

    {item, state} = Crawly.Utils.pipe(pipelines, item, state)

    # filter state is updated
    assert %{"my_id" => true} = state.duplicates_filter
    # unchanged
    assert item == @valid

    # run again with same item and updated state should drop the item
    assert {false, state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "DuplicatesFilter is inactive when item_id is not set" do
    pipelines = [Crawly.Pipelines.DuplicatesFilter]
    item = @valid
    state = %{}

    {item, state} = Crawly.Utils.pipe(pipelines, item, state)

    # filter state is not updated
    assert Map.has_key?(state, :duplicates_filter) == false

    # run with same item and updated state should not drop the item
    assert {%{} = item, state} = Crawly.Utils.pipe(pipelines, item, state)
    assert Map.has_key?(state, :duplicates_filter) == false

    # unchanged
    assert item == @valid
  end
end
