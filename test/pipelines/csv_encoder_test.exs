defmodule Pipelines.CSVEncoderTest do
  use ExUnit.Case, async: false

  @valid %{first: "some", second: "data"}
  test "Converts a single-level map to a csv string with global config" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: [:first, :second]}]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert is_binary(item)
    assert item == ~S("some","data")
  end

  test "Converts a single-level map to a csv string with tuple config" do
    pipelines = [{Crawly.Pipelines.CSVEncoder, fields: [:first, :second]}]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert is_binary(item)
    assert item == ~S("some","data")
  end
end
