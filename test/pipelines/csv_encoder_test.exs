defmodule Pipelines.CSVEncoderTest do
  use ExUnit.Case, async: false

  @valid %{first: "some", second: "data"}
  test "Converts a single-level map to a csv string with fields config" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: [:first, :second]}]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert is_binary(item)
    assert item == ~S("some","data")
  end

  test "Drops an item if fields are not declared" do
    pipelines = [{Crawly.Pipelines.CSVEncoder}]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert item == false
  end
end
