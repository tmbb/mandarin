defmodule Mandarin.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :mandarin,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "Mandarin",
      description: "Generators for fully-featured CRUD views.",
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs
                README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tmbb/mandarin"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bootstrap5components, "~> 0.5"},
      {:gettext, "~> 0.26"},
      {:sourceror, "~> 1.7"},
      {:inflex, "~> 2.1"},
      {:ex_doc, "~> 0.36", only: :dev}
    ]
  end
end
