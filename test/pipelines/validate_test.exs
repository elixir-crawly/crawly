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

  setup do
    on_exit(fn ->
      Application.put_env(:crawly, :item, nil)
    end)
  end

  test "Returns item unchanged when has required fields" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [Crawly.Pipelines.Validate]
    item = @valid
    state = %{}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)
    assert item == @valid
  end

  test "Drops items when missing required fields" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [Crawly.Pipelines.Validate]
    item = @invalid_missing
    state = %{}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "Drops items when required fields are equal to nil" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [Crawly.Pipelines.Validate]
    item = @invalid_nil
    state = %{}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end
end
