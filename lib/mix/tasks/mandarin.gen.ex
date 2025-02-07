defmodule Mix.Tasks.Mandarin.Gen do
  use Mix.Task

  @shortdoc "Lists all available Phoenix generators"

  @moduledoc """
  Lists all available Phoenix generators.

  ## CRUD related generators

  The table below shows a summary of the contents created by the CRUD generators:

  | Task | Schema | Migration | Context | Controller | View | LiveView |
  |:------------------ |:-:|:-:|:-:|:-:|:-:|:-:|
  | `mandarin.gen.embedded` | x |   |   |   |   |   |
  | `mandarin.gen.schema`   | x | x |   |   |   |   |
  | `mandarin.gen.context`  | x | x | x |   |   |   |
  | `mandarin.gen.live`     | x | x | x |   |   | x |
  | `mandarin.gen.json`     | x | x | x | x | x |   |
  | `mandarin.gen.html`     | x | x | x | x | x |   |
  """

  def run(_args) do
    Mix.Task.run("help", ["--search", "mandarin.gen."])
  end
end
