defmodule Mix.Tasks.Bureaucrat do
  use Mix.Task

  @shortdoc "Prints Bureaucrat help information"

  @moduledoc """
  Prints Bureaucrat tasks and their information.

      mix bureaucrat

  """

  @doc false
  def run(args) do
    case args do
      [] -> general()
      _ -> Mix.raise "Invalid arguments, expected: mix bureaucrat"
    end
  end

  defp general() do
    Application.ensure_all_started(:bureaucrat)
    Mix.shell.info "Bureaucrat v#{Application.spec(:bureaucrat, :vsn)}"
    Mix.shell.info "Productive. Reliable. Fast."
    Mix.shell.info "A productive web framework that does not compromise speed and maintainability."
    Mix.shell.info "\nAvailable tasks:\n"
    Mix.Tasks.Help.run(["--search", "bureaucrat."])
  end
end
