defmodule Pipelines.CSVEncoderTest do
  use ExUnit.Case, async: false

  @valid %{first: "some", second: "data"}
  @nested_valid %{first: "some", second: [%{some: "data1", other: "data2"}]}

  test "CSVEncoder converts a single-level map to a csv string" do
    Application.put_env(:crawly, :item, [:first, :second])

    pipelines = [Crawly.Pipelines.CSVEncoder]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert is_binary(item)
    assert item == ~S("some","data")
  end

  test "CSVEncoder converts a nested map to a csv string and flattens anything beyond the first level to json" do
    Application.put_env(:crawly, :item, [:first, :second])

    pipelines = [Crawly.Pipelines.CSVEncoder]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert is_binary(item)
    assert item == ~S("some","[{\"some\":\"data1\"},{\"other\":\"data2\"}]")
  end
end
