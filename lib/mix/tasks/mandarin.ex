defmodule Mix.Tasks.Mandarin do
  use Mix.Task

  @shortdoc "Prints Mandarin help information"

  @moduledoc """
  Prints Mandarin tasks and their information.

      mix mandarin
  """

  @doc false
  def run(args) do
    case args do
      [] -> general()
      _ -> Mix.raise("Invalid arguments, expected: mix mandarin")
    end
  end

  defp general() do
    Application.ensure_all_started(:mandarin)
    Mix.shell().info("Mandarin v#{Application.spec(:mandarin, :vsn)}")
    Mix.shell().info("Generators for your application's admin interface.")

    Mix.shell().info("\nAvailable tasks:\n")
    Mix.Tasks.Help.run(["--search", "mandarin."])
  end
end
