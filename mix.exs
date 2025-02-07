defmodule Mandarin.MixProject do
  use Mix.Project

  def project do
    [
      app: :mandarin,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_preload_in_result, path: "../ecto_preload_in_result"},
      {:bootstrap5components, path: "../bootstrap5components"},
      {:gettext, "~> 0.26"},
      {:sourceror, "~> 1.7"},
      {:inflex, "~> 2.1"},
      {:ex_doc, "~> 0.36", only: :dev}
    ]
  end
end
