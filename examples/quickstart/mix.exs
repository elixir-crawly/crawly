defmodule Quickstart.MixProject do
  use Mix.Project

  def project do
    [
      app: :quickstart,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Quickstart.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crawly, path: "../.."},
      {:floki, "~> 0.26.0"}
    ]
  end
end
