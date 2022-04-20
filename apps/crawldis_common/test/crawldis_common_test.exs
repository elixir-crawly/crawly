defmodule CrawldisCommonTest do
  use ExUnit.Case
  doctest CrawldisCommon

  test "greets the world" do
    assert CrawldisCommon.hello() == :world
  end
end
