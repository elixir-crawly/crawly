# Installation guide
---

Crawly requires Elixir v1.7 or higher. In order to make a Crawly
project execute the following steps:

1. Generate an new Elixir project: `mix new <project_name> --sup`
2. Add Crawly to you mix.exs file
    ```elixir
    def deps do
        [{:crawly, "~> 0.6.0"}]
    end
    ```
3. Fetch crawly: `mix deps.get`