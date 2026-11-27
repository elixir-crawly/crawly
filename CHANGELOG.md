# Changelog

All notable changes to Crawly are documented here. Pull request numbers refer
to <https://github.com/elixir-crawly/crawly/pulls>.

## 0.18.0 - 2026-11-28

The first release in over two years. It moves Crawly to current Elixir, Erlang
and dependency versions and removes code that no longer works. Read the
breaking changes before upgrading.

### Breaking changes

- **Elixir 1.18 or newer is required.** CI runs on current Elixir and
  Erlang/OTP releases, up to Elixir 1.20 and OTP 29. (#313, #315, #316)
- **`Crawly.fetch/2` has a new shape.** (#306)
  - It returns `{:ok, %HTTPoison.Response{}}` or `{:error, %HTTPoison.Error{}}`
    instead of a bare response.
  - The option for HTTP client options is renamed from `:request_options` to
    `:request_opts`. The new `:fetcher` option picks the fetcher module.
  - The configured middlewares are no longer applied to the request.
  - The `:with` option is gone. Use the new `Crawly.fetch_with_spider/3` to
    fetch a page and run a spider's `parse_item/1` on it. It returns what
    `parse_item/1` returns, usually a `Crawly.ParsedItem`. Item pipelines are
    not run.

  ```elixir
  # 0.17
  response = Crawly.fetch(url, request_options: [recv_timeout: 15_000])
  {response, parsed_item, items, state} = Crawly.fetch(url, with: MySpider)

  # 0.18
  {:ok, response} = Crawly.fetch(url, request_opts: [recv_timeout: 15_000])
  %Crawly.ParsedItem{items: items} = Crawly.fetch_with_spider(url, MySpider)
  ```

- **The Splash fetcher is removed.** Splash is no longer maintained and its
  Docker images don't run on Apple Silicon. Configs that use
  `{Crawly.Fetchers.Splash, ...}` must switch to
  `Crawly.Fetchers.CrawlyRenderServer` or a custom `Crawly.Fetchers.Fetcher`.
  (#319)
- **Poison is replaced by Elixir's built-in `JSON` module.** (#325)
  - `Crawly.Pipelines.JSONEncoder`, the HTTP API, YML spiders and
    `CrawlyRenderServer` all use `JSON` now.
  - Poison is no longer a dependency of Crawly. If your project used it
    through Crawly, add it to your own `mix.exs`.
  - Items that are structs must implement the `JSON.Encoder` protocol
    (for example with `@derive JSON.Encoder`), otherwise `JSONEncoder` logs an
    error and drops the item.
- **HTTPoison 3 and hackney 4.** (#326)
  - `HTTPoison.Response` and `HTTPoison.Error` keep the same fields, so
    spiders don't need changes.
  - hackney 4 is a rewrite. If you pass proxy, SSL or other low-level options
    through `Crawly.Middlewares.RequestOptions`, check them against the
    [HTTPoison](https://hexdocs.pm/httpoison) and
    [hackney](https://hexdocs.pm/hackney) docs.
- **Floki 0.38** is used in development, tests and the standalone release
  (was 0.33). Spiders that depend on Floki themselves should update to
  `{:floki, "~> 0.38"}`.

### Added

- `Crawly.fetch_with_spider/3`. (#306)
- `:normalise_url` option for `Crawly.Middlewares.UniqueRequest`. It takes a
  one-argument function that turns a URL into the key used to detect
  duplicates. By default trailing slashes are still trimmed. (#295)
- `Crawly.Fetchers.HTTPoisonFetcher` sets default timeouts: `timeout: 8_000`
  (how long to wait to connect) and `recv_timeout: 5_000` (how long to wait
  for the response), in milliseconds. Options set on the request or through
  `Crawly.Middlewares.RequestOptions` override them. HTTPoison 3 / hackney 4
  have no receive timeout by default, so without this a server that never
  answers would block a worker forever. (#326)
- Documentation for per-spider request headers. (#312)

### Fixed

- Crawly compiles with `ex_json_schema` on OTP 28. (#314)
- Logger file backend is set up through `logger_backends`, which removes the
  deprecation warning on current Elixir. (#321)
- The library compiles without warnings, and CI treats warnings as errors.
  (#320, #322)

### Security

Dependency updates clear every advisory reported by `mix hex.audit`,
including a critical one in hackney 1.x (custom CA certificates not
restricting trust). (#326)

- httpoison 2.3 → 3.0, hackney 1.25 → 4.12, idna 6.1 → 8.0, certifi 2.15 → 2.19
- plug 1.20.3 → 1.20.4
- Unused lock entries removed, including phoenix 1.6 and earmark.

### Internal

- New `Crawly.TestCase` resets shared state around each test. (#317)
- End-to-end test that crawls a local copy of books.toscrape.com
  (`mix test --only e2e`). (#324)
- excoveralls 0.18, logger_file_backend 0.1, updated ex_doc and mdex.
- Quieter test output. (#307, #318, #323)
- Credo fixes. (#305)

## 0.17.2 - 2024-07-04

- Fix `Crawly.Utils.list_spiders/0`. (#300)

## 0.17.1 - 2024-07-03

- Fix starting the Crawly interactive shell on Elixir 1.17. (#299)
- `Crawly.Middlewares.RobotsTxt` takes the User-Agent from the request.
  (#294)
- Fix a `Protocol.UndefinedError` by using a fallback. (#287)

## 0.17.0 - 2024-04-09

- New `Crawly.Fetchers.CrawlyRenderServer` fetcher for Puppeteer-based
  JavaScript rendering. (#272)
- The HTTP API starts automatically with Crawly. (#292)
- The HTTP API lists spiders with `Crawly.Engine.list_known_spiders/0`. (#291)
- HTTPoison updated to 2.2. (#293)
- CI moved to GitHub Actions. (#289)
- Higher log level for some messages. (#282)
