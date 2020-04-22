defmodule Pipelines.CSVEncoderTest do
  use ExUnit.Case, async: false

  @item %{first: "some", second: "data"}
  @state %{}

  test "Converts a single-level map to a csv string with fields config" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: [:first, :second]}]

    {item, _state} = Crawly.Utils.pipe(pipelines, @item, @state)

    assert is_binary(item)
    assert item == ~S("some","data")
  end

  test "Drops an item if fields are empty" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: []}]

    {item, _state} = Crawly.Utils.pipe(pipelines, @item, @state)

    assert item == false
  end

  test "Drops an item if fields are not declared" do
    pipelines = [{Crawly.Pipelines.CSVEncoder}]

    {item, _state} = Crawly.Utils.pipe(pipelines, @item, @state)

    assert item == false
  end
end
