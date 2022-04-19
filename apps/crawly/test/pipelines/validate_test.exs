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

  test "Returns item unchanged when has required fields" do
    Application.put_env(:crawly, :item, [:title, :author])
    pipelines = [{Crawly.Pipelines.Validate, fields: [:title, :author]}]
    item = @valid
    state = %{spider_name: Test, crawl_id: "test"}

    {item, _state} = Crawly.Utils.pipe(pipelines, item, state)
    assert item == @valid
  end

  test "Drops items when missing required fields with global config" do
    pipelines = [{Crawly.Pipelines.Validate, fields: [:title, :author]}]
    item = @invalid_missing
    state = %{spider_name: Test, crawl_id: "test"}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "Drops items when missing required fields with tuple config" do
    pipelines = [{Crawly.Pipelines.Validate, fields: [:title, :author]}]
    item = @invalid_missing
    state = %{spider_name: Test, crawl_id: "test"}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end

  test "Drops items when required fields are equal to nil" do
    pipelines = [{Crawly.Pipelines.Validate, fields: [:title, :author]}]
    item = @invalid_nil
    state = %{spider_name: Test, crawl_id: "test"}

    {false, _state} = Crawly.Utils.pipe(pipelines, item, state)
  end
end
