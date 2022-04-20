defmodule CrawldisProcessorTest do
  use ExUnit.Case
  doctest CrawldisProcessor

  test "greets the world" do
    assert CrawldisProcessor.hello() == :world
  end
end
