defmodule GenSpiderTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  test "when path is incorrect it sends an error message to console" do
    captured_output =
      capture_io(:stderr, fn ->
        Mix.Tasks.Crawly.Gen.Spider.run([
          "--spidername",
          "MySpider",
          "--filepath",
          "./lib/spiders/my_spider.ex"
        ])
      end)

    assert String.contains?(
             captured_output,
             "Error writing file: directory in the filepath doesn't exist"
           )
  end

  describe "with valid path" do
    test "it creates the spider in the passed directory" do
      captured_output =
        capture_io(fn ->
          Mix.Tasks.Crawly.Gen.Spider.run([
            "--spidername",
            "MySpider",
            "--filepath",
            "./test/mix/tasks/my_spider.ex"
          ])
        end)

      assert String.contains?(
               captured_output,
               "Done"
             )

      assert File.exists?("./test/mix/tasks/my_spider.ex")

      File.rm_rf("./test/mix/tasks/my_spider.ex")
    end
  end
end
