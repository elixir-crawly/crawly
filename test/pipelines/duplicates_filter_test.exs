defmodule Pipelines.DuplicatesFilterTest do
  use ExUnit.Case, async: false

  @valid %{data: [%{some: "nested_data"}], id: "my_id"}

  test "Drops duplicate items with the same item_id value through global config" do
    pipelines = [{Crawly.Pipelines.DuplicatesFilter, item_id: :id}]
    item = @valid
    state = %{spider_name: Test, crawl_id: "test"}

    {item, state} = Crawly.Utils.pipe(pipelines, item, state)

    # filter state is updated
    assert %{"my_id" => true} = state.duplicates_filter
    # unchanged
    assert item == @valid

    # run again with same item and updated state should drop the item
    assert {false, ^state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "Drops duplicate items with the same item_id value through tuple config" do
    pipelines = [{Crawly.Pipelines.DuplicatesFilter, item_id: :id}]
    item = @valid
    state = %{spider_name: Test, crawl_id: "test"}

    {item, state} = Crawly.Utils.pipe(pipelines, item, state)

    # filter state is updated
    assert %{"my_id" => true} = state.duplicates_filter
    # unchanged
    assert item == @valid

    # run again with same item and updated state should drop the item
    assert {false, ^state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "Inactive when item_id is not set" do
    pipelines = [Crawly.Pipelines.DuplicatesFilter]
    item = @valid
    state = %{spider_name: Test, crawl_id: "test"}

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        {item, state} = Crawly.Utils.pipe(pipelines, item, state)
        # filter state is not updated
        assert Map.has_key?(state, :duplicates_filter) == false

        # run with same item and updated state should not drop the item
        assert {%{} = item, state} = Crawly.Utils.pipe(pipelines, item, state)
        assert Map.has_key?(state, :duplicates_filter) == false

        # unchanged
        assert item == @valid
      end)

    assert log =~
             "Duplicates filter pipeline is inactive, item_id option is required"
  end
end
