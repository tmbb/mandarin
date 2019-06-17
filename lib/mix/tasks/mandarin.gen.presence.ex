defmodule Mix.Tasks.Mandarin.Gen.Presence do
  @shortdoc "Generates a Presence tracker"

  @moduledoc """
  Generates a Presence tracker for your application.

      mix mandarin.gen.presence

      mix mandarin.gen.presence MyPresence

  The only argument is the module name of the Presence tracker,
  which defaults to Presence.

  A new file will be generated in `lib/my_app_web/channels/presence.ex`,
  where `my_app_web` is the snake cased version of the module name provided.
  """
  use Mix.Task

  @doc false
  def run([]) do
    run(["Presence"])
  end

  def run([alias_name]) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix mandarin.gen.presence can only be run inside an application directory")
    end

    context_app = Mix.Mandarin.context_app()
    otp_app = Mix.Mandarin.otp_app()
    web_prefix = Mix.Mandarin.web_path(context_app)
    inflections = Mix.Mandarin.inflect(alias_name)

    inflections =
      Keyword.put(inflections, :module, "#{inflections[:web_module]}.#{inflections[:scoped]}")

    binding =
      inflections ++
        [
          otp_app: otp_app,
          pubsub_server: Module.concat(inflections[:base], PubSub)
        ]

    files = [
      {:eex, "presence.ex", Path.join(web_prefix, "channels/#{binding[:path]}.ex")}
    ]

    Mix.Mandarin.copy_from(paths(), "priv/templates/mandarin.gen.presence", binding, files)

    Mix.shell().info("""

    Add your new module to your supervision tree,
    in lib/#{otp_app}/application.ex:

        children = [
          ...
          #{binding[:module]}
        ]

    You're all set! See the Mandarin.Presence docs for more details:
    http://hexdocs.pm/mandarin/Mandarin.Presence.html
    """)
  end

  defp paths do
    [".", :mandarin]
  end
end
