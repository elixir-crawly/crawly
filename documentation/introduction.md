# Crawly intro
---

Crawly is an application framework for crawling web sites and
extracting structured data which can be used for a wide range of
useful applications, like data mining, information processing or
historical archival.

## Walk-through of an example spider

In order to show you what Crawly brings to the table, we’ll walk you
through an example of a Crawly spider using the simplest way to run a spider.

Here’s the code for a spider that scrapes blog posts from the Erlang
Solutions blog:  https://www.erlang-solutions.com/blog.html,
following the pagination:

```elixir
defmodule Esl do
@behaviour Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.erlang-solutions.com"

  def init() do
    [
      start_urls: ["https://www.erlang-solutions.com/blog.html"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # Getting new urls to follow
    urls =
      response.body
      |> Floki.find("a.more")
      |> Floki.attribute("href")
      |> Enum.uniq()

    # Convert URLs into requests
    requests =
      Enum.map(urls, fn url ->
        url
        |> build_absolute_url(response.request_url)
        |> Crawly.Utils.request_from_url()
      end)

    # Extract item from a page, e.g.
    # https://www.erlang-solutions.com/blog/introducing-telemetry.html
    title =
      response.body
      |> Floki.find("article.blog_post h1:first-child")
      |> Floki.text()

    author =
      response.body
      |> Floki.find("article.blog_post p.subheading")
      |> Floki.text(deep: false, sep: "")
      |> String.trim_leading()
      |> String.trim_trailing()

    time =
      response.body
      |> Floki.find("article.blog_post p.subheading time")
      |> Floki.text()

    url = response.request_url

    %Crawly.ParsedItem{
      :requests => requests,
      :items => [%{title: title, author: author, time: time, url: url}]
    }
  end

  def build_absolute_url(url, request_url) do
    URI.merge(request_url, url) |> to_string()
  end
end
```

Put this code into your project and run it using the Crawly REST API:
`curl -v localhost:4001/spiders/Esl/schedule`

When it finishes you will get the ESL.jl file stored on your
filesystem containing the following information about blog posts:

```json
{"url":"https://www.erlang-solutions.com/blog/erlang-trace-files-in-wireshark.html","title":"Erlang trace files in Wireshark","time":"2018-06-07","author":"by Magnus Henoch"}
{"url":"https://www.erlang-solutions.com/blog/railway-oriented-development-with-erlang.html","title":"Railway oriented development with Erlang","time":"2018-06-13","author":"by Oleg Tarasenko"}
{"url":"https://www.erlang-solutions.com/blog/scaling-reliably-during-the-world-s-biggest-sports-events.html","title":"Scaling reliably during the World’s biggest sports events","time":"2018-06-21","author":"by Erlang Solutions"}
{"url":"https://www.erlang-solutions.com/blog/escalus-4-0-0-faster-and-more-extensive-xmpp-testing.html","title":"Escalus 4.0.0: faster and more extensive XMPP testing","time":"2018-05-22","author":"by Konrad Zemek"}
{"url":"https://www.erlang-solutions.com/blog/mongooseim-3-1-inbox-got-better-testing-got-easier.html","title":"MongooseIM 3.1 - Inbox got better, testing got easier","time":"2018-07-25","author":"by Piotr Nosek"}
....
```

## What just happened?

When you ran the curl command:
```curl -v localhost:4001/spiders/Esl/schedule```

Crawly runs a spider ESL, Crawly looked for a Spider definition inside
it and ran it through its crawler engine.

The crawl started by making requests to the URLs defined in the
start_urls attribute of the spider's init, and called the default
callback method `parse_item`, passing the response object as an
argument. In the parse callback, we loop:
1. Look through all pagination the elements using a Floki Selector and
extract absolute URLs to follow. URLS are converted into Requests,
using
`Crawly.Utils.request_from_url()` function
2. Extract item(s) (items are defined in separate modules, and this part
will be covered later on)
3. Return a Crawly.ParsedItem structure which is containing new
requests to follow and items extracted from the given page, all
following requests are going to be processed by the same `parse_item` function.

Crawly is fully asynchronous. Once the requests are scheduled, they
are picked up by separate workers and are executed in parallel. This
also means that other requests can keep going even if some request
fails or an error happens while handling it.


While this enables you to do very fast crawls (sending multiple
concurrent requests at the same time, in a fault-tolerant way) Crawly
also gives you control over the politeness of the crawl through a few
settings. You can do things like setting a download delay between each
request, limiting the amount of concurrent requests per domain or
respecting robots.txt rules

```
This is using JSON export to generate the JSON lines file, but you can
easily extend it to change the export format (XML or CSV, for
example).

```

## What else?

You’ve seen how to extract and store items from a website using
Crawly, but this is just a basic example. Crawly provides a lot of
powerful features for making scraping easy and efficient, such as:

1. Flexible request spoofing (for example user-agents rotation,
cookies management (this feature is planned.))
2. Items validation, using pipelines approach.
3. Filtering already seen requests and items.
4. Filter out all requests which targeted at other domains.
5. Robots.txt enforcement.
6. Concurrency control.
7. HTTP API for controlling crawlers.
8. Interactive console, which allows you to create and debug spiders more easily.
