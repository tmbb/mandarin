defmodule Mix.Tasks.Mandarin do
  use Mix.Task

  @shortdoc "Prints Mandarin help information"

  @moduledoc """
  Prints Mandarin tasks and their information.

      $ mix phx

  To print the Mandarin version, pass `-v` or `--version`, for example:

      $ mix phx --version

  """

  @version Mix.Project.config()[:version]

  @impl true
  @doc false
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Mandarin v#{@version}")
  end

  def run(args) do
    case args do
      [] -> general()
      _ -> Mix.raise "Invalid arguments, expected: mix phx"
    end
  end

  defp general() do
    Application.ensure_all_started(:phoenix)
    Mix.shell().info "Mandarin v#{Application.spec(:phoenix, :vsn)}"
    Mix.shell().info "Peace of mind from prototype to production"
    Mix.shell().info "\n## Options\n"
    Mix.shell().info "-v, --version        # Prints Mandarin version\n"
    Mix.Tasks.Help.run(["--search", "mandarin."])
  end
end
