# books.toscrape.com fixture

`html/` is a copy of part of https://books.toscrape.com (a sandbox site made
for scraping practice), downloaded with `wget --page-requisites --convert-links`:

- `index.html` and `catalogue/page-1.html` … `catalogue/page-9.html`
- the 180 book pages linked from those listings
- the CSS, JS and fonts those pages use

Links to pages that were not downloaded (categories, catalogue page 10+) were
rewritten by wget to point at https://books.toscrape.com, so a crawler that
stays on the local host never hits a 404 here.

Manual changes after the download:

- The cover images (`media/`, ~11 MB) were deleted to keep the repo small.
  Every `/media/...` request is answered with `placeholder.png` instead
  (see `nginx.conf`), so pages still render and nothing 404s. Crawly tests only read the HTML.
- Font files saved as `name.ext?v=...` were renamed to `name.ext`, so web
  servers can find them.

## expected_books.json

The 180 books on the 9 local catalogue pages (`path`, `title`, `price`), as
the e2e test expects the spider to store them. It was extracted from the HTML
with a standalone regex script, not with the spider's Floki code, so the test
compares the crawl against an independent answer. Regenerate it only if
`html/` changes.
