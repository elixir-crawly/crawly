defmodule Crawldis.MixProject do
  use Mix.Project

  def project do
    [
      app: :crawldis,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Crawldis.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:delta_crdt, "~> 0.6.3"},
      {:crawly, in_umbrella: true},
      {:exsync, "~> 0.2", only: :dev},
      { :uuid, "~> 1.1" }
    ]
  end

  defp aliases do
    [
      setup: "cmd echo pass"
    ]
  end
end
