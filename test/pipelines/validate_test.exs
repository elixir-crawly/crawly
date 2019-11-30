defmodule Pipelines.ValidateTest do
  use ExUnit.Case, async: false

  @valid %{
    title: "title",
    author: "data"
  }
  @invalid_missing %{
    title: "title"
  }
  @invalid_nil %{
    title: "title",
    author: nil
  }

  test "ValidateItem item with required fields are not dropped, item returned unchanged" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [Crawly.Pipelines.Validate]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)
    assert item == @valid
  end

  test "ValidateItem items with missing required fields are dropped" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [Crawly.Pipelines.Validate]
    item = @invalid_missing
    state = %{}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "ValidateItem required item fields with nil are dropped" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [Crawly.Pipelines.Validate]
    item = @invalid_nil
    state = %{}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end
end
