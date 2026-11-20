# LocalBooks

The [quickstart](../quickstart) spider, built against the Crawly source in
this repository and pointed at the local copy of books.toscrape.com from
`test/e2e`.

Start the site, then run the crawl from this directory:

```bash
docker compose -f ../../test/e2e/docker-compose.yml up -d --build --wait
mix deps.get
mix run -e 'LocalBooks.crawl() |> IO.inspect()'
```

The end-to-end crawl test lives in Crawly itself: `test/e2e/books_crawl_test.exs`
(run with `mix test --only e2e` from the repository root).

Items end up in `tmp/LocalBooks.BooksSpider_<timestamp>_<crawl_id>.jl`.
Set `BOOKS_BASE_URL` to crawl a different copy of the site.
