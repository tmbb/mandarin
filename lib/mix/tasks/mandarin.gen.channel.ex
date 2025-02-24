defmodule Mix.Tasks.Mandarin.Gen.Channel do
  @shortdoc "Generates a Phoenix channel"

  @moduledoc """
  Generates a Phoenix channel.

      $ mix mandarin.gen.channel Room

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
  alias Mix.Tasks.Mandarin.Gen

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix mandarin.gen.channel must be invoked from within your *_web application root directory"
      )
    end

    [channel_name] = validate_args!(args)
    context_app = Mix.Mandarin.context_app()
    web_prefix = Mix.Mandarin.web_path(context_app)
    web_test_prefix = Mix.Mandarin.web_test_path(context_app)
    binding = Mix.Mandarin.inflect(channel_name)
    binding = Keyword.put(binding, :module, "#{binding[:web_module]}.#{binding[:scoped]}")

    Mix.Mandarin.check_module_name_availability!(binding[:module] <> "Channel")

    test_path = Path.join(web_test_prefix, "channels/#{binding[:path]}_channel_test.exs")
    case_path = Path.join(Path.dirname(web_test_prefix), "support/channel_case.ex")

    maybe_case =
      if File.exists?(case_path) do
        []
      else
        [{:eex, "channel_case.ex", case_path}]
      end

    Mix.Mandarin.copy_from(
      paths(),
      "priv/templates/mandarin.gen.channel",
      binding,
      [
        {:eex, "channel.ex", Path.join(web_prefix, "channels/#{binding[:path]}_channel.ex")},
        {:eex, "channel_test.exs", test_path}
      ] ++ maybe_case
    )

    user_socket_path = Mix.Mandarin.web_path(context_app, "channels/user_socket.ex")

    if File.exists?(user_socket_path) do
      Mix.shell().info("""

      Add the channel to your `#{user_socket_path}` handler, for example:

          channel "#{binding[:singular]}:lobby", #{binding[:module]}Channel
      """)
    else
      Mix.shell().info("""

      The default socket handler - #{binding[:web_module]}.UserSocket - was not found.
      """)

      if Mix.shell().yes?("Do you want to create it?") do
        Gen.Socket.run(~w(User --from-channel #{channel_name}))
      else
        Mix.shell().info("""

        To create it, please run the mix task:

            mix mandarin.gen.socket User

        Then add the channel to the newly created file, at `#{user_socket_path}`:

            channel "#{binding[:singular]}:lobby", #{binding[:module]}Channel
        """)
      end
    end
  end

  @spec raise_with_help() :: no_return()
  defp raise_with_help do
    Mix.raise("""
    mix mandarin.gen.channel expects just the module name, following capitalization:

        mix mandarin.gen.channel Room

    """)
  end

  defp validate_args!(args) do
    unless length(args) == 1 and args |> hd() |> valid_name?() do
      raise_with_help()
    end

    args
  end

  defp valid_name?(name) do
    name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  defp paths do
    [".", :phoenix]
  end
end
