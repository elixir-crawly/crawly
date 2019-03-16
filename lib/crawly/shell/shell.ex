defmodule Crawly.Shell do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_response(url) do
    HTTPoison.start()
    {:ok, response} = HTTPoison.get(url)
    GenServer.call(__MODULE__, {:store_response, response})
  end

  def response() do
    GenServer.call(__MODULE__, :get_response)
  end

  def init(_args) do
    {:ok, %{}}
  end

  def handle_call({:store_response, response}, _from, state) do
    state = Map.put(state, "response", response)
    {:reply, :ok, state}
  end

  def handle_call(:get_response, _from, state) do
    {:reply, Map.get(state, "response"), state}
  end
end
