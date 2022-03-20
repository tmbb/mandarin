defmodule Mix.Tasks.Mandarin.Uninstall do
  @shortdoc "Uninstall a Mandarin context"

  @moduledoc """
  Installs the files into your application
  """
  use Mix.Task

  require EEx

  # Why are we using an "Install" structure?
  # Uninstalling is the inverse of installing, so it actually makes sense
  # to use the same structure for both inverse tasks
  alias Mix.Mandarin.Install
  alias Mandarin.Naming

  @switches [web: :string]

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix mandarin.uninstall can only be run inside an application directory")
    end

    context_app = Mix.Mandarin.context_app()
    app = Atom.to_string(context_app)
    web_prefix = Mix.Mandarin.web_path(context_app)

    install = build(args, app, web_prefix)

    # Here we should document what we WON'T do:
    #
    # - Don't remove pagination capabilities from the Repo;
    #   This should be done manually if you want to actually
    #   remove all traces of Mandarin from your application.
    #   This task only removes a single Mandarin context.
    #
    # - Don't add any new files;
    #   We only remove files added by the other generators

    # What we actually do:
    #
    # - Remove the routes from the router
    #   (this will raise and exception if the 'router.ex' file contains invalid Elixir code)
    uninstall_from_router(install)
    # - Delete the files and directories
    delete_files_and_directories(install)
    # - Remove migrations created by the Mandarin generators
    remove_migrations_for_this_context(install)

    # Give the user some feedback on what has happened
    print_shell_instructions(install)
  end

  def build(args, app, web_path) do
    {_optional, args, _} = OptionParser.parse(args, switches: @switches)

    context_camel_case =
      case args do
        [arg] -> arg
        _ -> Mix.raise(~s'mix mandarin.install requires a context name (e.g. "Admin")')
      end

    context_app = Mix.Mandarin.context_app()
    context_app_camelcase = context_app |> to_string() |> Macro.camelize()
    context_underscore = Macro.underscore(context_camel_case)
    web_module = "#{context_app_camelcase}Web"
    mandarin_web_module = Naming.mandarin_web_module(context_app)
    layout_view_underscore = "#{context_underscore}_layout_view"
    layout_view_camel_case = Macro.camelize(layout_view_underscore)

    %Install{
      app: app,
      context_app: context_app,
      context_camel_case: inspect(context_camel_case),
      mandarin_web_module: mandarin_web_module,
      web_module: web_module,
      context_underscore: context_underscore,
      layout_view_camel_case: layout_view_camel_case,
      layout_view_underscore: layout_view_underscore,
      web_path: web_path
    }
  end

  def write_p!(path, content) do
    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end

  defp remove_migrations_for_this_context(%Install{} = install) do
    context = install.context_underscore
    migration_suffix = "__mandarin_#{context}.exs"
    migrations_directory = "priv/repo/migrations"

    for rel_path <- File.ls!(migrations_directory) do
      abs_path = Path.join(migrations_directory, rel_path)

      if String.ends_with?(abs_path, migration_suffix) do
        File.rm!(abs_path)
      end
    end
  end

  defp remove_pipeline_and_scope(router_text, %Install{} = install) do
    context = install.context_underscore
    context_atom = String.to_atom("#{context}_layout")
    scope_string = "/#{context}"

    # The only way to remove AST elements from the Sourceror AST
    # is through patches; this means we can't simply replace
    # the AST we want to delete, we need to create patches
    # and apply them later

    parsed_router_text =
      case Sourceror.parse_string(router_text) do
        {:ok, parsed} ->
          parsed

        {:error, _} ->
          # Give the user some Mandarin-specific feedback
          Mix.shell().error("""
          ** Your 'router.ex' file contains a syntax error.
             Mandarin couldn't remove the pipeline or scope for the context.
             Please ensure your 'router.ex' file contains valid Elixir code.
          """)

          # Actually raise the syntax error and stop execution
          Sourceror.parse_string!(router_text)
      end

    {_quoted, patches} =
      Macro.postwalk(parsed_router_text, [], fn quoted, patches ->
        case quoted do
          {:pipeline, _meta1, [{:__block__, _meta2, [^context_atom]} | _]} ->
            add_replacement_patch(patches, "", quoted)

          {:scope, _meta1, [{:__block__, _meta2, [^scope_string]} | _]} ->
            add_replacement_patch(patches, "", quoted)

          _quoted ->
            {quoted, patches}
        end
      end)

    # Apply the patches and reformat the code
    router_text
    |> Sourceror.patch_string(patches)
    |> Code.format_string!()
  end

  defp add_replacement_patch(patches, replacement, quoted) do
    range = Sourceror.get_range(quoted)
    patch = %{range: range, change: replacement}
    {quoted, [patch | patches]}
  end

  # Injects code into the Router module to create custom pipelines and scopes
  defp uninstall_from_router(%Install{} = install) do
    router_path = Path.join([install.web_path, "router.ex"])

    if File.exists?(router_path) do
      new_router_text =
        router_path
        |> File.read!()
        |> remove_pipeline_and_scope(install)

      File.write!(router_path, new_router_text)
    else
      Mix.shell().info("""
      No "#{router_path}" file was found.
      """)
    end
  end

  @doc false
  def delete_files_and_directories(%Install{} = install) do
    context_app = install.context_app
    ctx_basename = install.context_underscore

    # Web directory for the Mandarin context
    # (Mandarin purposefully couples web contexts and application contexts)
    web_prefix = Mix.Mandarin.web_path(context_app)
    web_context_dir = Path.join([web_prefix, ctx_basename])
    # Application directory for the Mandarin context:
    context_dir = Mix.Mandarin.context_lib_path(context_app, ctx_basename)

    # Delete the web files:
    File.rm_rf!(web_context_dir)
    # Delete the context files:
    File.rm_rf!(context_dir)

    :ok
  end

  @doc false
  def print_shell_instructions(%Install{} = _install) do
    Mix.shell().info("""

    Uninstalled context.
    """)
  end
end
