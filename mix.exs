defmodule Crawly.Mixfile do
  use Mix.Project

  def project do
    [



      app: :crawly,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :sasl, :httpoison],
      mod: {Crawly.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:floki, "~> 0.20.0"},
      {:uuid, "~> 1.1"},
      {:poison, "~> 3.1"},
      {:gollum, path: "/Users/olegtarasenko/repos/gollum"}
    ]
  end
end
