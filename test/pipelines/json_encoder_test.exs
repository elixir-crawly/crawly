defmodule Pipelines.JSONEncoderTest do
  use ExUnit.Case, async: false

  @valid %{data: [%{some: "nested_data"}]}

  test "Converts a given map to a json string" do
    pipelines = [Crawly.Pipelines.JSONEncoder]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)

    assert is_binary(item)
    assert item =~ @valid.data |> hd() |> Map.get(:some)
    assert item =~ "data"
    assert item =~ "some"
  end
end
