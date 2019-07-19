defmodule Mix.Tasks.Mandarin.Install do
  @shortdoc "Generates controller, views, and context for an HTML resource"

  @moduledoc """
  Installs the files into your application
  """
  use Mix.Task

  require EEx

  alias Mix.Mandarin.Install

  @switches [web: :string]

  def build(args, app, web_path) do
    {_optional, args, _} = OptionParser.parse(args, switches: @switches)

    context_camel_case =
      case args do
        [arg] -> arg
        _ -> Mix.raise(~s'mix mandarin.install requires a context name (i.e. "Admin")')
      end

    context_app = Mix.Mandarin.context_app()
    context_app_camelcase = context_app |> to_string() |> Macro.camelize()
    context_underscore = Macro.underscore(context_camel_case)
    web_module = "#{context_app_camelcase}Web"
    layout_view_underscore = "#{context_underscore}_layout_view"
    layout_view_camel_case = Macro.camelize(layout_view_underscore)

    %Install{
      app: app,
      context_camel_case: context_camel_case,
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

    layout_dir = "#{install.context_underscore}_layout"

    # These paths are relative to the user's project (because they are used at runtime)
    layout_html_path = Path.join([web_prefix, "templates", layout_dir, "layout.html.eex"])

    main_header_html_path =
      Path.join([web_prefix, "templates", layout_dir, "main-header.html.eex"])

    sidebar_html_path = Path.join([web_prefix, "templates", layout_dir, "sidebar.html.eex"])

    layout_view_path =
      Path.join([web_prefix, "views", "#{install.context_underscore}_layout_view.ex"])

    # Index page
    index_template_path =
      Path.join([
        web_prefix,
        "templates",
        "#{install.context_underscore}",
        "index",
        "index.html.eex"
      ])

    index_controller_path =
      Path.join([
        web_prefix,
        "controllers",
        "#{install.context_underscore}",
        "index_controller.ex"
      ])

    index_view_path =
      Path.join([web_prefix, "views", "#{install.context_underscore}", "index_view.ex"])

    # Add the extra scope and pipeline to the Router
    customize_router(install)

    # Add pagination capabilities to the Repo
    customize_repo(install)

    paths = [layout_html_path, main_header_html_path, sidebar_html_path, layout_view_path]

    prompt_for_conflicts(paths)

    write_p!(layout_html_path, layout_html(install))
    write_p!(main_header_html_path, main_header_html(install))
    write_p!(sidebar_html_path, sidebar_html(install))
    write_p!(layout_view_path, layout_view(install))
    # Index page
    write_p!(index_template_path, index_template(install))
    write_p!(index_controller_path, index_controller(install))
    write_p!(index_view_path, index_view(install))

    print_shell_instructions(install)
  end

  # Injects code into the Router module to create custom pipelines and scopes
  defp customize_router(install) do
    router_path = Path.join([install.web_path, "router.ex"])

    if File.exists?(router_path) do
      router_contents = File.read!(router_path)

      requires_mandarin_router? =
        String.match?(router_contents, ~r/\n\s*require\s+Mandarin.Router\s*\n/)

      pipeline_and_scope = new_pipeline_and_scope(install, requires_mandarin_router?)
      inject_eex_before_final_end(pipeline_and_scope, router_path)
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
        inject_eex_before_final_end(use_paginator, repo_path)
      end
    else
      Mix.shell().info("""
      No "#{repo_path}" file was found.
      """)
    end
  end

  defp prompt_for_conflicts(_paths) do
    nil
  end

  defp inject_eex_before_final_end(content_to_inject, file_path) do
    file = File.read!(file_path)

    if String.contains?(file, String.trim(content_to_inject)) do
      :ok
    else
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> Kernel.<>(content_to_inject)
      |> Kernel.<>("end\n")
      |> write_file(file_path)
    end
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  # These paths are relative to the mandarin project (because they are used at compile time)
  @external_resource "priv/templates/mandarin.install/layout.html.eex"
  @external_resource "priv/templates/mandarin.install/main-header.html.eex"
  @external_resource "priv/templates/mandarin.install/sidebar.html.eex"
  @external_resource "priv/templates/mandarin.install/layout_view.ex"
  @external_resource "priv/templates/mandarin.install/router.ex"
  # Index page (contains a template, a view and a controller)
  @external_resource "priv/templates/mandarin.install/index.html.eex"
  @external_resource "priv/templates/mandarin.install/index_view.ex"
  @external_resource "priv/templates/mandarin.install/index_controller.ex"

  EEx.function_from_file(
    :defp,
    :layout_html,
    "priv/templates/mandarin.install/layout.html.eex",
    [:install]
  )

  EEx.function_from_file(
    :defp,
    :main_header_html,
    "priv/templates/mandarin.install/main-header.html.eex",
    [:_install]
  )

  EEx.function_from_file(
    :defp,
    :sidebar_html,
    "priv/templates/mandarin.install/sidebar.html.eex",
    [:_install]
  )

  EEx.function_from_file(
    :defp,
    :layout_view,
    "priv/templates/mandarin.install/layout_view.ex",
    [:install]
  )

  EEx.function_from_file(
    :defp,
    :new_pipeline_and_scope,
    "priv/templates/mandarin.install/router.ex",
    [:install, :requires_mandarin_router?]
  )

  EEx.function_from_file(
    :defp,
    :index_template,
    "priv/templates/mandarin.install/index.html.eex",
    [:_install]
  )

  EEx.function_from_file(
    :defp,
    :index_view,
    "priv/templates/mandarin.install/index_view.ex",
    [:install]
  )

  EEx.function_from_file(
    :defp,
    :index_controller,
    "priv/templates/mandarin.install/index_controller.ex",
    [:install]
  )

  @doc false
  def print_shell_instructions(%Install{} = install) do
    %Install{
      context_camel_case: context_camel_case,
      context_underscore: ctx,
      web_module: web_module,
      web_path: web_path,
      layout_view_camel_case: layout_view_camel_case,
      layout_view_underscore: layout_view_underscore
    } = install

    Mix.shell().info("""
    The following files have been generated:

      * "#{web_path}/views/#{layout_view_underscore}.ex"
          - the view for the admin controllers

      * "#{web_path}/templates/#{layout_view_underscore}/layout.html.eex"
          - the layout for the admin pages

      * "#{web_path}/templates/#{layout_view_underscore}/sidebar-links.html.eex"
          - the sidebar links for the admin pages;
            when a new resource is generated, a new link will be appended to this list

      * "#{web_path}/templates/#{layout_view_underscore}/sidebar.html.eex"
          - template for the sidebar in the admin pages

      * "#{web_path}/templates/#{ctx}/index.html.eex"
          - the template for the index page

      * "#{web_path}/views/#{ctx}/sidebar.html.eex"
          - the view for the index page

      * "#{web_path}/controllers/#{ctx}/sidebar.html.eex"
           - the controller for the index page

    A new pipeline and a new scope have been injected in the "#{web_path}/router.ex" file.
    Admin routes should be sent through this pipeline so that they use the right layout:

    The folowing code has been injected into your router (#{web_path}/router.ex):

        require Mandarin.Router

        pipeline :#{ctx}_layout do
          plug(:put_layout, {#{web_module}.#{layout_view_camel_case}, "layout.html"})
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
