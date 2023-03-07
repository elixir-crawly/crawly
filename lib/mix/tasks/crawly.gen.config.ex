defmodule Mix.Tasks.Crawly.Gen.Config do
  @moduledoc """
  Generate Crawly configuration

  A small helper that generates a crawly spider configuration
  """
  @shortdoc "Generate example crawly config"

  use Mix.Task

  @impl Mix.Task
  @spec run([binary]) :: binary()
  def run(_args \\ []) do
    config_path = "config/config.exs"

    case File.read(config_path) do
      {:ok, contents} ->
        has_crawly_section? = String.contains?(contents, "config :crawly")

        case has_crawly_section? do
          true ->
            Mix.shell().error("Already has crawly section. Ignoring")

          false ->
            config_first_line = "import Config"

            new_content =
              String.replace(
                contents,
                config_first_line,
                crawly_config_template()
              )

            File.write!(config_path, new_content)
            Mix.shell().info("Done!")
        end

      {:error, reason} ->
        Mix.shell().info(
          "No config_file: #{inspect(reason)} -> creating new one"
        )

        create_config_file(config_path)
        Mix.shell().info("Done!")
    end
  end

  defp create_config_file(path) do
    File.mkdir("./config")
    File.write(path, crawly_config_template())
  end

  defp crawly_config_template() do
    """
    import Config

    config :crawly,
      closespider_timeout: 10,
      concurrent_requests_per_domain: 8,
      closespider_itemcount: 100,

      middlewares: [
        Crawly.Middlewares.DomainFilter,
        Crawly.Middlewares.UniqueRequest,
        {Crawly.Middlewares.UserAgent, user_agents: ["Crawly Bot", "Google"]}
      ],
      pipelines: [
        # An item is expected to have all fields defined in the fields list
        {Crawly.Pipelines.Validate, fields: [:url]},

        # Use the following field as an item uniq identifier (pipeline) drops
        # items with the same urls
        {Crawly.Pipelines.DuplicatesFilter, item_id: :url},
        Crawly.Pipelines.JSONEncoder,
        {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"}
      ]
    """
  end
end
