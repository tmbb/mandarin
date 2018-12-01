defmodule Mix.Tasks.Mandarin.Gen.Channel do
  @shortdoc "Generates a Mandarin channel"

  @moduledoc """
  Generates a Mandarin channel.

      mix mandarin.gen.channel Room

  Accepts the module name for the channel

  The generated files will contain:

  For a regular application:

    * a channel in `lib/my_app_web/channels`
    * a channel test in `test/my_app_web/channels`

  For an umbrella application:

    * a channel in `apps/my_app_web/lib/app_name_web/channels`
    * a channel test in `apps/my_app_web/test/my_app_web/channels`

  """
  use Mix.Task

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix mandarin.gen.channel can only be run inside an application directory")
    end

    [channel_name] = validate_args!(args)
    context_app = Mix.Mandarin.context_app()
    web_prefix = Mix.Mandarin.web_path(context_app)
    test_prefix = Mix.Mandarin.web_test_path(context_app)
    binding = Mix.Mandarin.inflect(channel_name)
    binding = Keyword.put(binding, :module, "#{binding[:web_module]}.#{binding[:scoped]}")

    Mix.Mandarin.check_module_name_availability!(binding[:module] <> "Channel")

    Mix.Mandarin.copy_from(paths(), "priv/templates/mandarin.gen.channel", binding, [
      {:eex, "channel.ex", Path.join(web_prefix, "channels/#{binding[:path]}_channel.ex")},
      {:eex, "channel_test.exs",
       Path.join(test_prefix, "channels/#{binding[:path]}_channel_test.exs")}
    ])

    Mix.shell().info("""

    Add the channel to your `#{Mix.Mandarin.web_path(context_app, "channels/user_socket.ex")}` handler, for example:

        channel "#{binding[:singular]}:lobby", #{binding[:module]}Channel
    """)
  end

  @spec raise_with_help() :: no_return()
  defp raise_with_help do
    Mix.raise("""
    mix mandarin.gen.channel expects just the module name:

        mix mandarin.gen.channel Room

    """)
  end

  defp validate_args!(args) do
    unless length(args) == 1 do
      raise_with_help()
    end

    args
  end

  defp paths do
    [".", :mandarin]
  end
end
