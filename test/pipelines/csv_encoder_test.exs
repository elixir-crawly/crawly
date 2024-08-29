defmodule Pipelines.CSVEncoderTest do
  use ExUnit.Case

  @item %{first: "some", second: "data"}
  @state %{spider_name: Test, crawl_id: "test"}

  test "Converts a single-level map to a csv string with fields config" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: [:first, :second]}]

    {item, _state} = Crawly.Utils.pipe(pipelines, @item, @state)

    assert is_binary(item)
    assert item == ~S("some","data")
  end

  test "Drops an item if fields are empty" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: []}]

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        {item, _state} = Crawly.Utils.pipe(pipelines, @item, @state)
        assert item == false
      end)

    assert log =~
             "Dropping item: %{first: \"some\", second: \"data\"}. Reason: No fields declared for CSVEncoder"
  end

  test "Drops an item if fields are not declared" do
    pipelines = [{Crawly.Pipelines.CSVEncoder}]

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        {item, _state} = Crawly.Utils.pipe(pipelines, @item, @state)
        assert item == false
      end)

    assert log =~
             "Dropping item: %{first: \"some\", second: \"data\"}. Reason: No fields declared for CSVEncoder"
  end
end
