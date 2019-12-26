defmodule Crawly.Pipeline do
  @moduledoc """
  A behavior module for implementing a pipeline module

  A pipeline is a module which takes a given item, and executes a
  run callback on a given item.

  A state argument is used to share common information accros multiple
  items.

  An `opts` argument is used to pass configuration to the pipeline through tuple-based declarations.
  """
  @callback run(item :: map, state :: map()) ::
              {new_item :: map, new_state :: map}
              | {false, new_state :: map}

  @callback run(item :: map, state :: map(), args :: list(any())) ::
              {new_item :: map, new_state :: map}
              | {false, new_state :: map}
  @optional_callbacks run: 3
end
