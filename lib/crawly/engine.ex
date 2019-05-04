defmodule Crawly.Engine do
  @moduledoc """

  Engine module
  """
  require Logger

  use GenServer

  def start_spider(name) do
    Logger.info("Started:  #{name}")
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}}
  end
end
