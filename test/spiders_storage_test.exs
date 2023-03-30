defmodule SpidersStorageTests do
  use ExUnit.Case, async: false

  setup do
    Crawly.SpidersStorage.init()

    on_exit(fn ->
      Crawly.SpidersStorage.clear()
    end)

    :ok
  end

  test "Can create new items in spiders storage" do
    :ok = Crawly.SpidersStorage.put(TestSpider, "Some code")

    assert {:ok, "Some code"} == Crawly.SpidersStorage.get(TestSpider)
  end

  test "Can delete an object" do
    :ok = Crawly.SpidersStorage.put(TestSpider, "Some code")

    assert {:ok, "Some code"} == Crawly.SpidersStorage.get(TestSpider)

    :ok = Crawly.SpidersStorage.delete(TestSpider)
    assert {:error, :not_found} == Crawly.SpidersStorage.get(TestSpider)
  end

  test "Can override a given spider value" do
    :ok = Crawly.SpidersStorage.put(TestSpider, "Some code1")
    assert {:ok, "Some code1"} == Crawly.SpidersStorage.get(TestSpider)

    :ok = Crawly.SpidersStorage.put(TestSpider, "new value")
    assert {:ok, "new value"} == Crawly.SpidersStorage.get(TestSpider)
  end

  test "Can list all items in the storage" do
    :ok = Crawly.SpidersStorage.put(TestSpider1, "Some code")
    :ok = Crawly.SpidersStorage.put(TestSpider2, "Some code1")

    assert [TestSpider1, TestSpider2] == Enum.sort(Crawly.SpidersStorage.list())
  end
end
