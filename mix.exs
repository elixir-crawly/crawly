defmodule Crawly.Mixfile do
  use Mix.Project

  @source_url "https://github.com/oltarasenko/crawly"
  @version "0.14.0"

  def project do
    [
      app: :crawly,
      version: @version,
      name: "Crawly",
      elixir: "~> 1.14",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      deps: deps(),
      elixirc_options: [warnings_as_errors: true]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :sasl, :httpoison],
      mod: {Crawly.Application, []}
    ]
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP
      # application name
      name: "crawly",
      description: "High-level web crawling & scraping framework for Elixir.",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.7"},
      {:elixir_uuid, "~> 1.2"},
      {:poison, "~> 3.1"},
      {:gollum, "~> 0.4.0", hex: :new_gollum},
      {:plug_cowboy, "~> 2.0"},
      {:credo, "~> 1.5.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:earmark, "~> 1.2", only: :dev},
      {:meck, "~> 0.9", only: :test},
      {:excoveralls, "~> 0.14.6", only: :test},
      {:yaml_elixir, "~> 2.9"},
      {:ex_json_schema, "~> 0.9.2"},

      # Add floki only for crawly standalone release
      {:floki, "~> 0.33.0", only: [:dev, :test, :standalone_crawly]},
      {:logger_file_backend, "~> 0.0.11",
       only: [:test, :dev, :standalone_crawly]}
    ]
  end

  defp docs do
    [
      assets: "documentation/assets",
      logo: "documentation/assets/logo.png",
      extra_section: "documentation",
      extras: extras(),
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"],
      groups_for_modules: [
        "Building Spiders": [
          Crawly.Response,
          Crawly.Request,
          Crawly.Spider,
          Crawly.ParsedItem
        ],
        "Middlewares and Pipelines": ~r"Crawly\.(Pipeline|Middlewares)(.*)",
        "Under the Hood": [
          Crawly.Engine,
          Crawly.Manager,
          Crawly.Worker,
          Crawly.DataStorage,
          Crawly.DataStorage.Worker,
          Crawly.RequestsStorage,
          Crawly.RequestsStorage.Worker
        ]
      ],
      nest_modules_by_prefix: [
        Crawly.Middlewares,
        Crawly.Pipelines
      ]
    ]
  end

  defp extras do
    [
      "documentation/basic_concepts.md",
      "documentation/configuration.md",
      "documentation/http_api.md",
      "documentation/ethical_aspects.md",
      "documentation/experimental_ui.md",
      LICENSE: [title: "License"],
      "README.md": [title: "Introduction", file: "readme"]
    ]
  end
end
