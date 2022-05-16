defmodule CrawldisCommon.ClusterTest do
  use ExUnit.Case, async: false
  alias CrawldisCommon.Cluster

  setup do
    Cluster.list_requestors()
    |> Enum.each(&Cluster.stop_requestor/1)

    :ok
  end

  test "list_requestors/0 adds a requestor" do
    assert Cluster.list_requestors() == []
  end

  test "start_requestor/0 adds a requestor" do
    assert {:ok, id} = Cluster.start_requestor()
    assert is_binary(id)
    assert Cluster.list_requestors() |> length() == 1
  end

  test "stop_requestor/1 stops a requestor" do
    assert {:ok, requestor} = Cluster.start_requestor()
    assert :ok = Cluster.stop_requestor(requestor)
    assert Cluster.list_requestors() |> length() == 0
  end

  test "list_processors/0 lists processors"
  test "start_processor/0 adds a processor"
  test "stop_processor/1 adds a processor"
end
