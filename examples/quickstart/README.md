# Quickstart

The spider from the [Crawly README](../../README.md#quickstart), as a ready
project. It crawls <https://books.toscrape.com/> and writes the books it finds
to `/tmp/BooksToScrape_<timestamp>.jl`.

It uses Crawly from this repository (`{:crawly, path: "../.."}`). To use the
Hex release in your own project, depend on `{:crawly, "~> 0.18.0"}` instead.

Requires Elixir 1.18 or newer.

## Run it

```bash
mix deps.get
iex -S mix run -e "Crawly.Engine.start_spider(BooksToScrape)"
```

The crawl stops after 100 items or 10 seconds without new items (see
`config/config.exs`).
