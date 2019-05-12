defmodule Crawly do
  @moduledoc """
  Documentation for Crawly.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Crawly.hello
      :world

  """

  def fetch(url, headers \\ [], options \\ []) do
    HTTPoison.get(url, headers, options)
  end

end
