defmodule Crawldis.Parsers.CssSelectorParserTest do
  use ExUnit.Case, async: true
  alias Crawldis.Parsers.CssSelectorParser

  describe "css selector parser" do
    @html """
    <html>
      <some>text</some>
      <div>
        <a href="http://next-link.example.com" class="a">nested a</a>
        <a href="http://next-link2.example.com" class="b">nested b</a>
        <a href="http://next-link2.example.com" class="c">https://url.com</a>
      </div>
    </html>
    """

    test "extracts both items and requests" do
      assert %{requests: [_, _], items: [_]} = [requests: "div a['href']", items: "a.b"]
      |> do_parse()
    end
    test "extracts requests from inner text" do
      assert %{requests: [%_{url: "https://url.com"}]} = [requests: [".c", :inner_text]]
      |> do_parse()
    end
    defp do_parse(opts) do
      parsed = CssSelectorParser.run(%Crawly.ParsedItem{}, %{response: %{body: @html}}, opts)
    end
  end
end
