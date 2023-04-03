defmodule JobTest do
  use ExUnit.Case, async: false

  setup do
    Crawly.SimpleStorage.init()

    on_exit(fn ->
      Crawly.SimpleStorage.clear()
    end)

    :ok
  end

  test "creates a new job successfully" do
    :ok = Crawly.Models.Job.new("test-crawl-id", Spider)

    {:ok, job} = Crawly.Models.Job.get("test-crawl-id")

    assert job.id == "test-crawl-id"
    assert job.spider_name == "Spider"
    assert job.start != nil
    assert job.end == nil
    assert job.scraped_items == 0
    assert job.stop_reason == nil
  end

  test "Word Elixir is removed from spider name" do
    :ok = Crawly.Models.Job.new("test-crawl-id", Elixir.Spider)

    {:ok, job} = Crawly.Models.Job.get("test-crawl-id")

    assert job.id == "test-crawl-id"
    assert job.spider_name == "Spider"
    assert job.start != nil
    assert job.end == nil
    assert job.scraped_items == 0
    assert job.stop_reason == nil
  end

  test "updates an existing job successfully" do
    Crawly.Models.Job.new("test-crawl-id", Spider)

    :ok = Crawly.Models.Job.update("test-crawl-id", 10, :finished)
    {:ok, updated_job} = Crawly.Models.Job.get("test-crawl-id")

    assert updated_job.id == "test-crawl-id"
    assert updated_job.spider_name == "Spider"
    assert updated_job.start != nil
    assert updated_job.end != nil
    assert updated_job.scraped_items == 10
    assert updated_job.stop_reason == :finished
  end

  test "gets an existing job successfully" do
    Crawly.Models.Job.new("test-crawl-id", Spider)

    {:ok, job} = Crawly.Models.Job.get("test-crawl-id")

    assert job.id == "test-crawl-id"
    assert job.spider_name == "Spider"
    assert job.start != nil
    assert job.end == nil
    assert job.scraped_items == 0
    assert job.stop_reason == nil
  end

  test "returns {:error, reason} when getting a nonexistent job" do
    result = Crawly.Models.Job.get("nonexistent-crawl-id")

    assert result == {:error, :not_found}
  end
end
