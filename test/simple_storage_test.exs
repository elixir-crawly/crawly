defmodule SimpleStorageTests do
  use ExUnit.Case, async: false

  setup do
    Crawly.SimpleStorage.init()

    on_exit(fn ->
      Crawly.SimpleStorage.clear()
    end)

    :ok
  end

  test "Can create new items in spiders storage" do
    :ok = Crawly.SimpleStorage.put(:spiders, TestSpider, "Some code")

    assert {:ok, "Some code"} == Crawly.SimpleStorage.get(:spiders, TestSpider)
  end

  test "Can delete an object" do
    :ok = Crawly.SimpleStorage.put(:spiders, TestSpider, "Some code")

    assert {:ok, "Some code"} == Crawly.SimpleStorage.get(:spiders, TestSpider)

    :ok = Crawly.SimpleStorage.delete(:spiders, TestSpider)

    assert {:error, :not_found} ==
             Crawly.SimpleStorage.get(:spiders, TestSpider)
  end

  test "Can override a given spider value" do
    :ok = Crawly.SimpleStorage.put(:spiders, TestSpider, "Some code1")
    assert {:ok, "Some code1"} == Crawly.SimpleStorage.get(:spiders, TestSpider)

    :ok = Crawly.SimpleStorage.put(:spiders, TestSpider, "new value")
    assert {:ok, "new value"} == Crawly.SimpleStorage.get(:spiders, TestSpider)
  end

  test "Can list all items in the storage" do
    :ok = Crawly.SimpleStorage.put(:spiders, TestSpider1, "Some code")
    :ok = Crawly.SimpleStorage.put(:spiders, TestSpider2, "Some code1")

    assert [TestSpider1, TestSpider2] ==
             Enum.sort(Crawly.SimpleStorage.list(:spiders))
  end
end
