# HTTP API

---

Crawly supports a basic HTTP API, which allows to control the Engine
behaviour.

## Starting a spider

The following command will start a given Crawly spider:

```
curl -v localhost:4001/spiders/<spider_name>/schedule
```

## Stopping a spider

The following command will stop a given Crawly spider:

```
curl -v localhost:4001/spiders/<spider_name>/stop
```

## Getting currently running spiders

```
curl -v localhost:4001/spiders
```

## Getting spider stats

```
curl -v localhost:4001/spiders/<spider_name>/scheduled-requests
curl -v localhost:4001/spiders/<spider_name>/scraped-items
```
