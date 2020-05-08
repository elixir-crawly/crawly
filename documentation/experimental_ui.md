# Experimental UI
---

We believe that web scraping is a process. It might seem easy to extract first 
data items, however we believe that the data delivery requires a bit more efforts or
a process which supports it!

Our aim is to provide you with the following services:

1. Schedule (start and stop) your spiders on a cloud
2. View running jobs (performance based analysis)
3. View and validate scraped items for quality assurance and data analysis purposes.
4. View individual items and compare them with the actual website.

## Project status

Currently the project is in early alpha stage. We're constantly working on making
it more stable. And currently running it for long running jobs.
So far it did no show major problems, however we accept that there will be problems
on such early stages! If you are one of those who has them, please don't 
hesitate to report them here. 

## Setting it up

You can find setup examples [here](https://github.com/oltarasenko/crawly_ui/tree/master/examples)

On the highest level it's required to:
1. Add SendToUI pipeline to the list of your item pipelines (before encoder pipelines)
`{Crawly.Pipelines.Experimental.SendToUI, ui_node: :'ui@127.0.0.1'}`
2. Organize erlang cluster so Crawly nodes can find CrawlyUI node
in the example above I was using [erlang-node-discovery](https://github.com/oltarasenko/erlang-node-discovery)
application for this task, however any other alternative would also work.
For setting up erlang-node-discovery 
-  add the following code dependency to deps section of mix.exs
`{:erlang_node_discovery, git: "https://github.com/oltarasenko/erlang-node-discovery"}`
- add the following lines to the config.exs: 
```config :erlang_node_discovery,
          hosts: ["127.0.0.1", "crawlyui.com"],
          node_ports: [
            {:ui, 0}
          ]
```

## Testing it locally with a docker-compose

CrawlyUI ships with a docker compose which brings up UI, worker and database
nodes, so everything is ready for testing with just one command.

In order to try it:
1. clone crawly_ui repo: `git clone git@github.com:oltarasenko/crawly_ui.git`
2. build ui and worker nodes: `docker-compose build`
3. apply migrations: `docker-compose run ui bash -c "/crawlyui/bin/ec eval \"CrawlyUI.ReleaseTasks.migrate\""`
4. run it all: `docker-compose up`

## Live demo

Live demo is available as well. However it might be a bit unstable due to continues
releases process. Please give it a try and let us know what do you think

[Live Demo](http://18.216.221.122/)  

## Items browser

One of the cool features of the CrawlyUI is items browser which allows comparing
extracted data with a target website loaded in the IFRAME. However due to the
fact that most of the big sites would block iframes, it will not work for you.
Unless you install special browser extension to ignore X-Frame headers. For example
[Chrome extension](https://chrome.google.com/webstore/detail/ignore-x-frame-headers/gleekbfjekiniecknbkamfmkohkpodhe)

## Gallery

![Main Page](assets/main_page.png?raw=true)
--
![Items browser](assets/items_page.png?raw=true)
--
![Items browser search](assets/item_with_filters.png?raw=true)
--
![Items browser](assets/item_preview_example.png?raw=true)
