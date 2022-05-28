defmodule Mix.Tasks.Mandarin.InstallUninstallHelpers do
  @moduledoc false

  @switches [web: :string, user: :string]

  alias Mix.Mandarin.Install
  alias Mandarin.Naming

  def valid_context_name?(name) do
    # We already know the string is non-empty because
    # otherwise the OptionParser wouldn't have found it.
    c = String.at(name, 0)
    # Quick'n dirty test...
    c == String.upcase(c)
  end

  def build(args, app, web_path) do
    {optional, args, _} = OptionParser.parse(args, switches: @switches)

    context_camel_case =
      case args do
        [arg] ->
          if valid_context_name?(arg) do
            arg
          else
            Mix.raise(~s'mix mandarin.install requires a *valid* context name (e.g. "Admin")')
          end

        _ ->
          Mix.raise(~s'mix mandarin.install requires a context name (e.g. "Admin")')
      end

    context_app = Mix.Mandarin.context_app()
    context_app_camelcase = context_app |> to_string() |> Macro.camelize()
    context_underscore = Macro.underscore(context_camel_case)

    user_entity_name = Keyword.get(optional, :user)

    web_module = "#{context_app_camelcase}Web"
    mandarin_web_module = Naming.mandarin_web_module(context_app)
    layout_view_module = context_camel_case <> ".LayoutView"

    %Install{
      app: app,
      context_app: context_app,
      user_entity_name: user_entity_name,
      context_camel_case: context_camel_case,
      mandarin_web_module: mandarin_web_module,
      web_module: web_module,
      context_underscore: context_underscore,
      layout_view_module: layout_view_module,
      web_path: web_path
    }
  end
end
