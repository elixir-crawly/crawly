
  defmodule Crawldis.Parsers.CssSelectorParser do
    @moduledoc false
    @behaviour Crawly.Pipeline
    def run(previous_result, %{response: %{body: body}} = state, opts) do
      opts = Enum.into(opts, %{requests: nil, items: nil})
      {:ok, doc} = Floki.parse_document(body)
      item = previous_result
      |> Map.update(:requests, [], fn requests->
        parse_requests(doc, opts.requests) ++ requests
      end)
      |> Map.update(:items, [], fn prev->
        parse_items(doc, opts.items) ++  prev
      end)
      {item, state}
    end

    defp parse_requests(doc, nil), do: []
    defp parse_requests(doc, single) when is_binary(single), do: parse_requests(doc, [single])
    defp parse_requests(doc, selectors) do


      requests
    end
    defp parse_items(doc, nil), do: []
    defp parse_items(doc, single) when is_binary(single), do: parse_items(doc, [single])
    defp parse_items(doc, selectors) do


      items
    end

  end
