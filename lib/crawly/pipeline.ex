defmodule Crawly.Pipeline do
  @moduledoc """
  A behavior module for implementing a pipeline module

  A pipeline is a module which takes a given item, and executes a
  run callback on a given item.

  A state variable is used to share common information accros multiple
  items.
  """
  @callback run(item :: map, state :: map()) ::
              {new_item :: map, new_state :: map}
              | {false, new_state :: map}
end
