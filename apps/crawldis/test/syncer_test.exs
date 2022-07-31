defmodule Crawldis.SyncerTest do
  use ExUnit.Case, async: false
  alias Crawldis.Syncer


  test "Only one per node" do
    start_supervised!({Syncer, name: :something, node: :some@node, get_pid: fn -> self() end})
    start_supervised!({Syncer, name: :something2, node: :some@node, get_pid: fn -> self() end}, id: :other)
    assert_raise RuntimeError, fn ->
      start_supervised!({Syncer, name: :something2, node: :some@node, get_pid: fn -> self() end}, id: :other2)
    end
  end
end
