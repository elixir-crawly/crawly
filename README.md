# Crawly

[![Build Status](https://travis-ci.com/oltarasenko/crawly.svg?branch=master)](https://travis-ci.com/oltarasenko/crawly)
[![Coverage Status](https://coveralls.io/repos/github/oltarasenko/crawly/badge.svg?branch=coveralls)](https://coveralls.io/github/oltarasenko/crawly?branch=coveralls)

## Overview

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

## Requirements

1. Elixir "~> 1.7"
2. Works on Linux, Windows, OS X and BSD

## Installation

Add Crawly to you mix.exs file

```elixir
def deps do
    [{:crawly, "~> 0.6.0"}]
end
```

## Documentation

- [API Reference](https://hexdocs.pm/crawly/api-reference.html#content)
- [Quickstart](https://hexdocs.pm/crawly/quickstart.html)
- [Tutorial](https://hexdocs.pm/crawly/tutorial.html)

## Roadmap

1. [ ] Pluggable HTTP client
2. [ ] Retries support
3. [ ] Cookies support
4. [ ] XPath support
5. [ ] Project generators (spiders)
6. [ ] UI for jobs management

## Articles

1. Blog post on Erlang Solutions website: https://www.erlang-solutions.com/blog/web-scraping-with-elixir.html

## Example projects

1. Blog crawler: https://github.com/oltarasenko/crawly-spider-example
2. E-commerce websites: https://github.com/oltarasenko/products-advisor
3. Car shops: https://github.com/oltarasenko/crawly-cars

## Contributors

We would gladly accept your contributions! Please refer to the `Under The Hood` section on [HexDocs](https://hexdocs.pm/crawly/) for modules documentation.
