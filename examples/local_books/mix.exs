defmodule LocalBooks.MixProject do
  use Mix.Project

  def project do
    [
      app: :local_books,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LocalBooks.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # The Crawly source in this repository, not the Hex release
      {:crawly, path: "../.."},
      {:floki, "~> 0.33.0"}
    ]
  end
end
