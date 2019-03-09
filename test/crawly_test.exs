defmodule CrawlyTest do
  use ExUnit.Case
  doctest Crawly

  test "greets the world" do
    assert Crawly.hello() == :world
  end
end
