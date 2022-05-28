defmodule Mandarin.MixProject do
  use Mix.Project

  @version "0.7.0"

  def project do
    [
      app: :mandarin,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "guides/backoffice_demo.md"
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sourceror, "~> 0.10"},
      {:forage, "~> 0.7"},
      {:inflex, "~> 2.0.0"},
      {:ex_doc, "~> 0.23", only: :dev}
    ]
  end

  defp description() do
    "Admin interface generator"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "mandarin",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tmbb/mandarin"}
    ]
  end

  defp aliases() do
    [
      publish: "run scripts/publish.exs"
    ]
  end
end
