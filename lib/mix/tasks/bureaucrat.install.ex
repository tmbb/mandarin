defmodule Mix.Tasks.Bureaucrat.Install do
  @shortdoc "Generates controller, views, and context for an HTML resource"

  @moduledoc """
  Installs the files into your application
  """
  use Mix.Task

  require EEx

  alias Mix.Bureaucrat.Install

  @switches [web: :string]

  def build(args, web_path) do
    {_optional, args, _} = OptionParser.parse(args, switches: @switches)

    context_camel_case =
      case args do
        [arg] -> arg
        _ -> Mix.raise(~s'mix bureaucrat.install requires a context name (i.e. "Admin")')
      end

    context_app = Mix.Bureaucrat.context_app()
    context_app_camelcase = context_app |> to_string() |> Macro.camelize()
    context_underscore = Macro.underscore(context_camel_case)
    web_module = "#{context_app_camelcase}Web"
    layout_view_underscore = "#{context_underscore}_layout_view"
    layout_view_camel_case = Macro.camelize(layout_view_underscore)

    %Install{
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
      Mix.raise("mix bureaucrat.install can only be run inside an application directory")
    end

    context_app = Mix.Bureaucrat.context_app()
    web_prefix = Mix.Bureaucrat.web_path(context_app)
    _test_prefix = Mix.Bureaucrat.web_test_path(context_app)
    layout_dir = "#{install.context_underscore}_layout"

    install = build(args, web_prefix)

    # These paths are relative to the user's project (because they are used at runtime)
    layout_html_path = Path.join([web_prefix, "templates", layout_dir, "layout.html.eex"])

    main_header_html_path =
      Path.join([web_prefix, "templates", layout_dir, "main-header.html.eex"])

    sidebar_html_path = Path.join([web_prefix, "templates", layout_dir, "sidebar.html.eex"])

    layout_view_path =
      Path.join([web_prefix, "views", "#{install.context_underscore}_layout_view.ex"])

    paths = [layout_html_path, main_header_html_path, sidebar_html_path, layout_view_path]

    prompt_for_conflicts(paths)

    write_p!(layout_html_path, layout_html(install))
    write_p!(main_header_html_path, main_header_html(install))
    write_p!(sidebar_html_path, sidebar_html(install))
    write_p!(layout_view_path, layout_view(install))

    print_shell_instructions(install)
  end

  defp prompt_for_conflicts(_paths) do
    nil
  end

  # These paths are relative to the bureaucrat project (because they are used at compile time)
  @external_resource "priv/templates/bureaucrat.install/layout.html.eex"
  @external_resource "priv/templates/bureaucrat.install/main-header.html.eex"
  @external_resource "priv/templates/bureaucrat.install/sidebar.html.eex"
  @external_resource "priv/templates/bureaucrat.install/layout_view.ex"

  EEx.function_from_file(
    :defp,
    :layout_html,
    "priv/templates/bureaucrat.install/layout.html.eex",
    [:install]
  )

  EEx.function_from_file(
    :defp,
    :main_header_html,
    "priv/templates/bureaucrat.install/main-header.html.eex",
    [:_install]
  )

  EEx.function_from_file(
    :defp,
    :sidebar_html,
    "priv/templates/bureaucrat.install/sidebar.html.eex",
    [:_install]
  )

  EEx.function_from_file(
    :defp,
    :layout_view,
    "priv/templates/bureaucrat.install/layout_view.ex",
    [:install]
  )

  @doc false
  def print_shell_instructions(%Install{} = install) do
    app = Mix.Bureaucrat.context_app()

    Mix.shell().info("""
    The following files have been generated:

      * "#{app}/lib/#{install.web_path}/views/#{install.layout_view_underscore}.ex"
          - the view for the admin controllers

      * "#{app}/lib/#{install.web_path}/templates/#{install.layout_view_underscore}/layout.html.eex"
          - the layout for the admin pages

      * "#{app}/lib/#{install.web_path}/templates/#{install.layout_view_underscore}/sidebar-links.html.eex"
          - the sidebar links for the admin pages;
            when a new resource is generated, a new link will be appended to this list

      * "#{app}/lib/#{install.web_path}/templates/#{install.layout_view_underscore}/sidebar.html.eex"
          - template for the sidebar in the admin pages

    Now, you must customize your router, so that your pages can make use of the new layout.
    Require Bureaucrat.Router in your router in #{install.web_path}/router.ex:

        require Bureaucrat.Router

    Add a new pipeline to your router in #{install.web_path}/router.ex:

        pipeline :#{install.layout_view_underscore} do
          plug(:put_layout, {#{install.web_module}.#{install.layout_view_camel_case}, "layout.html"})
        end

    The admin routes must be sent through this pipeline.
    """)
  end
end
