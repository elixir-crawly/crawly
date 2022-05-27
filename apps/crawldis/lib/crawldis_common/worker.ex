defmodule Crawldis.Worker do
  @doc """
  Returns the via tuple to identify the worker
  """
  @callback via(String.t()) :: tuple()

  @doc """
  Stops the worker
  """
  @callback stop(String.t()) :: :ok
end
