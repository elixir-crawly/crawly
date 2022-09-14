defmodule QuickstartTest do
  use ExUnit.Case
  doctest Quickstart

  test "greets the world" do
    assert Quickstart.hello() == :world
  end
end
