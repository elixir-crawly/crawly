# Experimental UI

If you are interested in our attempts to make crawling more predictable,
have a glance on: https://github.com/oltarasenko/crawly_ui

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

## Setting up logger

You can send logs to CrawlyUI as well. In order to do that you have
to add the following (changing your node name of course) to your config:
``` 
# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [
    :console,
    {Crawly.Loggers.SendToUiBackend, :send_log_to_ui}
  ],
  level: :debug

config :logger, :send_log_to_ui, destination: {:"ui@127.0.0.1", CrawlyUI, :store_log}

```
