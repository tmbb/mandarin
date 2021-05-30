defmodule Mix.Tasks.Mandarin.Gen.Html do
  @shortdoc "Generates controller, views, and context for an HTML resource"

  @moduledoc """
  Generates controller, views, and context for an HTML resource.

      mix mandarin.gen.html Admin User users name:string age:integer

  The first argument is the context module followed by the schema module
  and its plural name (used as the schema table name).

  The context is an Elixir module that serves as an API boundary for
  the given resource. A context often holds many related resources.
  Therefore, if the context already exists, it will be augmented with
  functions for the given resource.

  > Note: A resource may also be split
  > over distinct contexts (such as `admin.User` and `Payments.User`).

  The schema is responsible for mapping the database fields into an
  Elixir struct.

  Overall, this generator will add the following files to `lib/`:

    * a context module in `lib/app/admin/admin.ex` for the admin API
    * a schema in `lib/app/admin/user.ex`, with an `users` table
    * a view in `lib/app_web/views/user_view.ex`
    * a controller in `lib/app_web/controllers/user_controller.ex`
    * default CRUD templates in `lib/app_web/templates/user`

  A migration file for the repository and test files for the context and
  controller features will also be generated.

  The location of the web files (controllers, views, templates, etc) in an
  umbrella application will vary based on the `:context_app` config located
  in your applications `:generators` configuration. When set, the Mandarin
  generators will generate web files directly in your lib and test folders
  since the application is assumed to be isolated to web specific functionality.
  If `:context_app` is not set, the generators will place web related lib
  and test files in a `web/` directory since the application is assumed
  to be handling both web and domain specific functionality.
  Example configuration:

      config :my_app_web, :generators, context_app: :my_app

  Alternatively, the `--context-app` option may be supplied to the generator:

      mix mandarin.gen.html Sales User users --context-app warehouse

  ## Web namespace

  By default, the controller and view will be namespaced by the schema name.
  You can customize the web module namespace by passing the `--web` flag with a
  module name, for example:

      mix mandarin.gen.html Sales User users --web Sales

  Which would generate a `lib/app_web/controllers/sales/user_controller.ex` and
  `lib/app_web/views/sales/user_view.ex`.

  ## Generating without a schema or context file

  In some cases, you may wish to bootstrap HTML templates, controllers, and
  controller tests, but leave internal implementation of the context or schema
  to yourself. You can use the `--no-context` and `--no-schema` flags for
  file generation control.

  ## table

  By default, the table name for the migration and schema will be
  the plural name provided for the resource. To customize this value,
  a `--table` option may be provided. For example:

      mix mandarin.gen.html admin User users --table cms_users

  ## binary_id

  Generated migration can use `binary_id` for schema's primary key
  and its references with option `--binary-id`.

  ## Default options

  This generator uses default options provided in the `:generators`
  configuration of your application. These are the defaults:

      config :your_app, :generators,
        migration: true,
        binary_id: false,
        sample_binary_id: "11111111-1111-1111-1111-111111111111"

  You can override those options per invocation by providing corresponding
  switches, e.g. `--no-binary-id` to use normal ids despite the default
  configuration or `--migration` to force generation of the migration.

  Read the documentation for `mandarin.gen.schema` for more information on
  attributes.
  """
  use Mix.Task

  alias Mandarin.Naming
  alias Mix.Mandarin.Context
  alias Mix.Tasks.Mandarin.Gen
  require EEx

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix mandarin.gen.html can only be run inside an application directory")
    end

    {context, schema} = Gen.Context.build(args)

    # The user can disable the prompt by supplying the --yes switch
    unless "--yes" in args do
      Gen.Context.prompt_for_code_injection(context)
    end

    binding = [
      context: context,
      schema: schema,
      inputs: inputs(context),
      filters: filters(context)
    ]

    paths = Mix.Mandarin.generator_paths()

    prompt_for_conflicts(context)

    context
    |> maybe_add_links_to_sidebar()
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
  end

  @links_end "\n  <%# %% Resource Links - END %% %>"

  defp maybe_insert_links(file, context, schema) do
    contents = File.read!(file)
    IO.inspect(schema.alias)
    link_header = "    <%# * Sidebar link for #{inspect(schema.alias)} %>"

    case String.contains?(contents, link_header) do
      # The sidebar already contains a link to this resource
      # (probably because we're regenerating the files for the resource)
      true ->
        nil

      false ->
        case String.split(contents, @links_end, parts: 2) do
          [part1, part2] ->
            link = sidebar_link(context, schema)
            # Use the fact that `File.write!/2` works with iolists
            new_contents = [
              part1,
              "\n",
              link_header,
              "\n",
              String.trim_trailing(link),
              @links_end,
              part2
            ]

            File.write!(file, new_contents)

          _other ->
            # The user has deleted the link markers...
            nil
        end
    end
  end

  EEx.function_from_file(
    :defp,
    :sidebar_link,
    "priv/templates/mandarin.gen.html/sidebar-link.html.eex",
    [:context, :schema]
  )

  defp maybe_add_links_to_sidebar(%Context{schema: schema, context_app: context_app} = context) do
    sidebar_template_path = Mix.Tasks.Mandarin.Install.sidebar_path(context_app, context.basename)

    if File.exists?(sidebar_template_path) do
      maybe_insert_links(sidebar_template_path, context, schema)
    end

    context
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Kernel.++(context_files(context))
    |> Mix.Mandarin.prompt_for_conflicts()
  end

  defp context_files(%Context{generate?: true} = context) do
    Gen.Context.files_to_be_generated(context)
  end

  defp context_files(%Context{generate?: false}) do
    []
  end

  @doc false
  def files_to_be_generated(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Mandarin.web_path(context_app)
    test_prefix = Mix.Mandarin.web_test_path(context_app)
    web_path = to_string(schema.web_path)
    ctx_basename = context.basename

    feature_dir = Path.join([web_prefix, ctx_basename, schema.singular])
    template_dir = Path.join(feature_dir, "templates")

    controller_path = Path.join(feature_dir, "#{schema.singular}_controller.ex")
    view_path = Path.join(feature_dir, "#{schema.singular}_view.ex")
    controller_test_path =
      Path.join([
        test_prefix,
        "controllers",
        web_path,
        ctx_basename,
        "#{schema.singular}_controller_test.exs"
      ])

    html_templates =
      for name <- ~w(edit filters form index new show table) do
        filename = "#{name}.html.eex"
        output_path = Path.join(template_dir, filename)
        {:eex, filename, output_path}
      end


    [
      {:eex, "controller.ex", controller_path},
      {:eex, "view.ex", view_path},
      {:eex, "controller_test.exs", controller_test_path}
    ] ++ html_templates
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Mandarin.copy_from(paths, "priv/templates/mandarin.gen.html", binding, files)
    if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)
    context
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    ctx_web_path = Mix.Mandarin.web_path(ctx_app)
    Mix.shell().info("""

    Add the resource to your #{schema.web_namespace} :browser scope in #{ctx_web_path}/router.ex:

        scope "/#{schema.web_path}", #{inspect(context.basename)}, as: :#{context.basename} do
          pipe_through([:browser, :#{context.basename}_layout])
          ...
          Mandarin.Router.resources("/#{schema.plural}", #{inspect(schema.alias)}Controller)
        end

    You probably want to add some authentication to these routes.
    """)
  end

  defp inputs(%Context{schema: schema} = context) do
    attrs =
      Enum.map(schema.attrs, fn
        {_, {:references, _}} ->
          {nil, nil, nil}

        {key, :integer} ->
          {label(key), ~s(<%= number_input f, #{inspect(key)}, class: "form-control" %>),
           error(key)}

        {key, :float} ->
          {label(key),
           ~s(<%= number_input f, #{inspect(key)}, step: "any", class: "form-control" %>),
           error(key)}

        {key, :decimal} ->
          {label(key),
           ~s(<%= number_input f, #{inspect(key)}, step: "any", class: "form-control" %>),
           error(key)}

        {key, :boolean} ->
          {label(key), ~s(<%= checkbox f, #{inspect(key)}, class: "form-control" %>), error(key)}

        {key, :text} ->
          {label(key), ~s(<%= textarea f, #{inspect(key)}, class: "form-control" %>), error(key)}

        {key, :date} ->
          {label(key), ~s(<%= forage_date_input f, #{inspect(key)}, class: "form-control" %>),
           error(key)}

        {key, :time} ->
          {label(key), ~s(<%= time_select f, #{inspect(key)}, class: "form-control" %>),
           error(key)}

        {key, :utc_datetime} ->
          {label(key), ~s(<%= datetime_select f, #{inspect(key)}, class: "form-control" %>),
           error(key)}

        {key, :naive_datetime} ->
          {label(key), ~s(<%= datetime_select f, #{inspect(key)}, class: "form-control" %>),
           error(key)}

        {key, {:array, :integer}} ->
          {label(key), ~s(<%= multiple_select f, #{inspect(key)}, ["1": 1, "2": 2] %>),
           error(key)}

        {key, {:array, _}} ->
          {label(key),
           ~s(<%= multiple_select f, #{inspect(key)}, ["Option 1": "option1", "Option 2": "option2"] %>),
           error(key)}

        {key, _} ->
          {label(key), ~s(<%= text_input f, #{inspect(key)}, class: "form-control" %>),
           error(key)}
      end)

    assocs =
      Enum.map(schema.assocs, fn
        {key, _atom_singular_id, _full_module_name, atom_plural} ->
          path_part = Naming.singularize(atom_plural)
          path = "Routes.#{context.basename}_#{path_part}_path(@conn, :select)"

          {label(key),
           ~s'''
           <%= forage_select f, :#{key}, path: #{path} %>\
           ''', error(key)}
      end)

    attrs ++ assocs
  end

  defp filters(%Context{schema: schema} = context) do
    simple_filters =
      Enum.map(schema.attrs, fn {key, field_type} ->
        type =
          case field_type do
            {:references, _} -> nil
            :integer -> :numeric
            :float -> :numeric
            :decimal -> :numeric
            :boolean -> nil
            :text -> :text
            :string -> :text
            :date -> :date
            :time -> :numeric
            :utc_datetime -> :numeric
            :naive_datetime -> :numeric
            _ -> nil
          end

        case type do
          nil ->
            ""

          other when other in [:numeric, :date, :text] ->
            # Indent the text here becuase it's easier than indenting it in the template
            """
              <%= forage_horizontal_form_group #{inspect(key)} do %>
                <%= forage_#{other}_filter(f, #{inspect(key)}) %>
              <% end %>\
            """
        end
      end)

    assoc_filters =
      Enum.map(schema.assocs, fn {key, _atom_singular_id, _full_module_name, atom_plural} ->
        path_part = Naming.singularize(atom_plural)
        path = "Routes.#{context.basename}_#{path_part}_path(@conn, :select)"

        """
          <%= forage_horizontal_form_group #{inspect(key)} do %>
            <%= forage_select_filter f, :#{key}, path: #{path} %>
          <% end %>\
        """
      end)

    simple_filters ++ assoc_filters
  end

  defp label(key) do
    ~s(<%= label f, #{inspect(key)}, class: "control-label" %>)
  end

  defp error(field) do
    ~s(<%= error_tag f, #{inspect(field)} %>)
  end
end
