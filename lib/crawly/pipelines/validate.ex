defmodule Crawly.Pipelines.Validate do
  @moduledoc """
  Ensure that scraped item contains a set of required fields.

  ### Options
  If the fields to check are not provided, the pipeline does nothing.
  - `:fields`, required: The list of required fields. Fallsback to global config `:item`.

  ### Example Declaration
  ```
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:id, :url, :date]}
  ]
  ```

  ### Example Usage
  ```
  # Drops the scraped item that does not have the required fields
  iex> Validate.run(%{my: "field"}, %{}, fields: [:id])
  {false, %{}}
  ```
  """
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state, opts \\ []) do
    opts = Enum.into(opts, %{fields: nil})
    fields = Map.get(opts, :fields, [])

    validation_result =
      fields
      |> Enum.map(fn field ->
        case Map.get(item, field) do
          val when val == nil or val == :undefined or val == "" ->
            :invalid

          _ ->
            :valid
        end
      end)
      |> Enum.uniq()

    case validation_result do
      [:valid] ->
        {item, state}

      _ ->
        Logger.info(
          "Dropping item: #{inspect(item)}. Reason: missing required fields"
        )

        {false, state}
    end
  end
end
