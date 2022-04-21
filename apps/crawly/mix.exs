defmodule Crawly.Mixfile do
  use Mix.Project

  @version "0.13.0"

  def project do
    [
      app: :crawly,
      version: @version,
      name: "Crawly",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      aliases: aliases()
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
      {:logger_file_backend, "~> 0.0.11", only: [:test, :dev]}
    ]
  end

  defp aliases do
    [
      setup: "cmd echo pass"
    ]
  end
end
