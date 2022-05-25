defmodule Mix.Tasks.Mandarin.Install do
  @shortdoc "Generates controller, views, and context for an HTML resource"

  @moduledoc """
  Removes a mandarin context from your application
  """
  use Mix.Task
  alias Mix.Tasks.Mandarin.InstallUninstallHelpers

  require EEx

  alias Mix.Mandarin.Install
  alias Mandarin.Naming
  alias Mandarin.Injector

  def build(args, app, web_path) do
    InstallUninstallHelpers.build(args, app, web_path)
  end

  def write_p!(path, content) do
    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix mandarin.install can only be run inside an application directory")
    end

    context_app = Mix.Mandarin.context_app()
    app = Atom.to_string(context_app)
    web_prefix = Mix.Mandarin.web_path(context_app)
    _test_prefix = Mix.Mandarin.web_test_path(context_app)

    install = build(args, app, web_prefix)
    binding = [install: install]
    paths = Mix.Mandarin.generator_paths()

    # Add the extra scope and pipeline to the Router
    customize_router(install)

    # Add pagination capabilities to the Repo
    customize_repo(install)
    copy_new_files(install, paths, binding)
    print_shell_instructions(install)
  end

  # Injects code into the Router module to create custom pipelines and scopes
  defp customize_router(install) do
    router_path = Path.join([install.web_path, "router.ex"])

    if File.exists?(router_path) do
      # Generate the code we'll inject:
      pipeline_and_scope = new_pipeline_and_scope(install)

      # We should only add the pipeline and scope to the router if they don't exist already.
      # To detect whether they already exist, we will match the first non-empty line in the injected code.
      # Hopefully that line will be unique enough for our purposes.

      # Get the first non-empty line of the inhected code
      pipeline_start =
        pipeline_and_scope
        |> String.trim_leading()
        |> String.split("\n")
        |> Enum.at(0)
        |> String.trim()

      # Only inject the code if the file doesn't contain the start of the pipeline
      router_contents = File.read!(router_path)

      case String.contains?(router_contents, pipeline_start) do
        false ->
          Injector.inject_before_final_end(pipeline_and_scope, router_path)

        true ->
          Mix.shell().info("""
          Mandarin didn't inject a pipeline and scope for the curent context because they already exist.
          """)
      end
    else
      Mix.shell().info("""
      No "#{router_path}" file was found.
      """)
    end
  end

  # Injects code into the repo to make it capable of pagination
  defp customize_repo(install) do
    repo_path = Path.join(["lib", install.app, "repo.ex"])
    repo_contents = File.read!(repo_path)

    if File.exists?(repo_path) do
      unless String.contains?(repo_contents, "\n  use Paginator") do
        use_paginator = "\n  use Paginator\n"
        Injector.inject_before_final_end(use_paginator, repo_path)
      end
    else
      Mix.shell().info("""
      No "#{repo_path}" file was found.
      """)
    end
  end

  # Path to the sidebar template
  # This path must be accessible from outside this module
  # when we want to populate the sidebar links automatically
  def sidebar_path(context_app, context_underscore) do
    ctx_basename = context_underscore
    web_prefix = Mix.Mandarin.web_path(context_app)
    group_dir = Path.join([web_prefix, ctx_basename])
    layout_feature_dir = Path.join(group_dir, "_layout")
    layout_templates_dir = Path.join(layout_feature_dir, "templates")
    layout_sidebar_template_path = Path.join(layout_templates_dir, "sidebar.html.heex")

    layout_sidebar_template_path
  end

  def files_to_be_generated(%Install{} = install) do
    context_app = install.context_app
    ctx_basename = install.context_underscore

    web_prefix = Mix.Mandarin.web_path(context_app)
    # TODO: add tests for this functionality (at least for the index controller)
    _test_prefix = Mix.Mandarin.web_test_path(context_app)

    group_dir = Path.join([web_prefix, ctx_basename])

    mandarin_web_path = Naming.mandarin_web_path(web_prefix)
    # We'll generate two features: "index" and "layout"
    index_feature_dir = Path.join(group_dir, "index")
    index_controller_path = Path.join(index_feature_dir, "index_controller.ex")
    index_view_path = Path.join(index_feature_dir, "index_view.ex")
    index_template_path = Path.join([index_feature_dir, "templates", "index.html.heex"])

    layout_feature_dir = Path.join(group_dir, "_layout")
    layout_view_path = Path.join(layout_feature_dir, "layout_view.ex")
    layout_templates_dir = Path.join(layout_feature_dir, "templates")

    root_layout_template_path = Path.join(layout_templates_dir, "root.html.heex")
    app_layout_template_path = Path.join(layout_templates_dir, "app.html.heex")
    live_layout_template_path = Path.join(layout_templates_dir, "live.html.heex")

    layout_sidebar_template_path = sidebar_path(context_app, install.context_underscore)

    # Only generate this file if it doesn't exist already
    # (it's quite likely that the user will want to customize this file)
    maybe_mandarin_web =
      case File.exists?(mandarin_web_path) do
        # The file that will allow Mandarin to use "vertical slices" even if the rest
        # of the application uses the (IMO inferior) horizontal slices.
        false -> [{:eex, "mandarin_web.ex", mandarin_web_path}]
        true -> []
      end

    web_templates = [
      # Files related to the default "index" page for a mandarin CRUD interface
      {:eex, "index_controller.ex", index_controller_path},
      {:eex, "index_view.ex", index_view_path},
      {:eex, "index.html.heex", index_template_path},
      # Files related to the "layout" page for a mandarin CRUD interface
      # (we adopt the app/live distinction from the normal phoenix generators)
      {:eex, "layout_view.ex", layout_view_path},
      {:eex, "root.html.heex", root_layout_template_path},
      {:eex, "app.html.heex", app_layout_template_path},
      {:eex, "live.html.heex", live_layout_template_path},
      {:eex, "sidebar.html.heex", layout_sidebar_template_path}
    ]

    maybe_mandarin_web ++ web_templates
  end

  router_template = "priv/templates/mandarin.install/router.ex"
  @external_resource router_template

  EEx.function_from_file(
    :defp,
    :new_pipeline_and_scope,
    router_template,
    [:install]
  )

  @doc false
  def copy_new_files(%Install{} = install, paths, binding) do
    files = files_to_be_generated(install)
    Mix.Mandarin.copy_from(paths, "priv/templates/mandarin.install", binding, files)
  end

  @doc false
  def print_shell_instructions(%Install{} = install) do
    %Install{
      context_camel_case: context_camel_case,
      context_underscore: ctx,
      web_module: web_module,
      web_path: web_path,
      layout_view_module: layout_view_module
    } = install

    files =
      for {_eex, file, path} <- files_to_be_generated(install), into: %{} do
        {file, path}
      end

    Mix.shell().info("""
    The following files have been generated:

      * "#{files["layout_view.ex"]}"
          - the layout view for the mandarin pages

      * "#{files["root.html.heex"]}",
        "#{files["app.html.heex"]}",
        "#{files["live.html.heex"]}"
          - the layout templates for the mandarin pages

      * "#{files["sidebar.html.heex"]}"
          - the sidebar links for the admin pages;
            when a new resource is generated, a new link will be appended to this list

      * "#{files["index_view.ex"]}"
          - the view for the index page

      * "#{files["index_controller.ex"]}"
          - the controller for the index page

      * "#{files["index.html.heex"]}"
          - the template for the index page

    A new pipeline and a new scope have been injected in the "#{web_path}/router.ex" file.
    Admin routes should be sent through this pipeline so that they use the right layout:

    The folowing code has been injected into your router (#{web_path}/router.ex):

        require Mandarin.Router

        pipeline :#{ctx}_layout do
          plug(:put_layout, {#{web_module}.#{layout_view_module}, "layout.html"})
        end

        scope "/#{ctx}", #{web_module}.#{context_camel_case}, as: :#{ctx} do
          pipe_through([:browser, :#{ctx}_layout])
          # Add routes here...
          get "/", IndexController, :index
        end

    When you create your resources, you must add the routes under the "/#{ctx}" scope.
    """)
  end
end
