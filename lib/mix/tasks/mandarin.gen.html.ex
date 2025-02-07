defmodule Mix.Tasks.Mandarin.Gen.Html do
  @shortdoc "Generates context and controller for an HTML resource"

  @moduledoc """
  Generates controller, HTML views, and context for an HTML resource.

      mix mandarin.gen.html Accounts User users name:string age:integer

  The first argument is the context module followed by the schema module
  and its plural name (used as the schema table name).

  The context is an Elixir module that serves as an API boundary for
  the given resource. A context often holds many related resources.
  Therefore, if the context already exists, it will be augmented with
  functions for the given resource.

  > Note: A resource may also be split
  > over distinct contexts (such as `Accounts.User` and `Payments.User`).

  The schema is responsible for mapping the database fields into an
  Elixir struct. It is followed by an optional list of attributes,
  with their respective names and types. See `mix mandarin.gen.schema`
  for more information on attributes.

  Overall, this generator will add the following files to `lib/`:

    * a context module in `lib/app/accounts.ex` for the accounts API
    * a schema in `lib/app/accounts/user.ex`, with an `users` table
    * a controller in `lib/app_web/controllers/user_controller.ex`
    * an HTML view collocated with the controller in `lib/app_web/controllers/user_html.ex`
    * default CRUD templates in `lib/app_web/controllers/user_html`

  ## The context app

  A migration file for the repository and test files for the context and
  controller features will also be generated.

  The location of the web files (controllers, HTML views, templates, etc) in an
  umbrella application will vary based on the `:context_app` config located
  in your applications `:generators` configuration. When set, the Phoenix
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

  By default, the controller and HTML view will be namespaced by the schema name.
  You can customize the web module namespace by passing the `--web` flag with a
  module name, for example:

      mix mandarin.gen.html Sales User users --web Sales

  Which would generate a `lib/app_web/controllers/sales/user_controller.ex` and
  `lib/app_web/controllers/sales/user_html.ex`.

  ## Customizing the context, schema, tables and migrations

  In some cases, you may wish to bootstrap HTML templates, controllers,
  and controller tests, but leave internal implementation of the context
  or schema to yourself. You can use the `--no-context` and `--no-schema`
  flags for file generation control.

  You can also change the table name or configure the migrations to
  use binary ids for primary keys, see `mix mandarin.gen.schema` for more
  information.
  """
  use Mix.Task

  alias Mix.Mandarin.{Context, Schema, Injector}
  alias Mix.Tasks.Mandarin.Gen

  require EEx

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix mandarin.gen.html must be invoked from within your *_web application root directory"
      )
    end

    {context, schema} = Gen.Context.build(args)
    Gen.Context.prompt_for_code_injection(context)

    binding = [context: context, schema: schema, inputs: inputs(schema)]
    paths = Mix.Mandarin.generator_paths()

    prompt_for_conflicts(context)

    customize_router(context)

    context
    |> copy_new_files(paths, binding)
    |> add_sidebar_link()
    |> print_shell_instructions()
  end

  defp prompt_for_conflicts(context) do
    proceed_without_confirmation = Keyword.get(context.opts, :yes)

    context
    |> files_to_be_generated()
    |> Kernel.++(context_files(context))
    |> Mix.Mandarin.prompt_for_conflicts(proceed_without_confirmation)
  end

  defp context_files(%Context{generate?: true} = context) do
    Gen.Context.files_to_be_generated(context)
  end

  defp context_files(%Context{generate?: false}) do
    []
  end

  @doc false
  def files_to_be_generated(%Context{} = context) do
    %Context{
      schema: schema,
      context_app: context_app,
      basename: basename
    } = context

    singular = schema.singular
    app_dir = Mix.Mandarin.context_lib_path(context_app, "")
    web_prefix = Mix.Mandarin.web_path(context_app)
    test_prefix = Mix.Mandarin.web_test_path(context_app)
    # web_path = to_string(schema.web_path)
    web_context_pre = Path.join([web_prefix, basename])
    controller_pre = Path.join([web_prefix, basename, singular])
    test_pre = Path.join([test_prefix, basename])

    [
      {:eex, "controller.ex", Path.join([controller_pre, "#{singular}_controller.ex"])},
      {:eex, "live_edit.ex", Path.join([controller_pre, "#{singular}_live_edit.ex"])},
      {:eex, "live_browse.ex", Path.join([controller_pre, "#{singular}_live_browse.ex"])},
      {:eex, "live_show.ex", Path.join([controller_pre, "#{singular}_live_show.ex"])},
      {:eex, "impl_b5c_resource.ex", Path.join([controller_pre, "#{singular}_impl_b5c_resource.ex"])},
      {:eex, "live_browse.html.heex",
       Path.join([controller_pre, "#{singular}_html", "#{singular}_live_browse.html.heex"])},
      {:eex, "live_form.html.heex",
       Path.join([controller_pre, "#{singular}_html", "#{singular}_live_form.html.heex"])},
      {:eex, "live_show.html.heex", Path.join([controller_pre, "#{singular}_html",
       "#{singular}_live_show.html.heex"])},
      {:eex, "html.ex", Path.join([controller_pre, "#{singular}_html.ex"])},
      {:eex, "web_test.exs", Path.join([test_pre, "#{singular}_test.exs"])},
      {:new_eex, "mandarin_notifications.ex", Path.join(app_dir, "mandarin_notifications.ex")},
      {:new_eex, "mandarin_web.ex", Path.join(web_prefix, "mandarin_web.ex")},
      # Layout and components
      {:new_eex, "mandarin_components.ex",
       Path.join([web_prefix, "components", "mandarin_components.ex"])},
      {:new_eex, "layouts.ex", Path.join(web_context_pre, "layouts.ex")},
      {:new_eex, "app.html.heex", Path.join([web_context_pre, "layouts", "app.html.heex"])},
      {:new_eex, "root.html.heex", Path.join([web_context_pre, "layouts", "root.html.heex"])},
      # Homepage files
      {:new_eex, "homepage_controller.ex", Path.join([web_context_pre, "homepage", "homepage_controller.ex"])},
      {:new_eex, "homepage.html.heex", Path.join([web_context_pre, "homepage", "homepage_html", "homepage.html.heex"])},
      {:new_eex, "homepage_html.ex", Path.join([web_context_pre, "homepage", "homepage_html.ex"])},
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Mandarin.copy_from(paths, "priv/templates/mandarin.gen.html", binding, files)
    if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)
    context
  end

  router_template = "priv/templates/mandarin.gen.html/router.ex"
  @external_resource router_template

  EEx.function_from_file(
    :defp,
    :new_pipeline_and_scope,
    router_template,
    [:context]
  )

  def add_sidebar_link(%Context{} = context) do
    schema = context.schema
    ctx_app = context.context_app
    basename = context.basename

    web_path = Mix.Mandarin.web_path(ctx_app)
    root_path = Path.join([web_path, basename, "layouts", "root.html.heex"])
    root_contents = File.read!(root_path)

    link_to_inject = """
                <.sidebar_link to={~p"#{schema.route_prefix}"}>
                  <%= dgettext("#{context.basename}", "#{schema.human_plural}") %>
                </.sidebar_link>\
      """

    code_after_link_injection =
      case Injector.inject_before(root_contents, "        </.sidebar_link_group>", link_to_inject) do
        {:ok, new_code} ->
          Mix.shell().info("""
          Mandarin has added the link to your sidebar.
          """)

          new_code

        :error ->
          Mix.shell().info("""
          Mandarin was unable to inject the new link in the sidebar.
          """)

          root_contents
      end

    File.write!(root_path, code_after_link_injection)

    context
  end

  # Injects code into the Router module to create custom pipelines and scopes
  def customize_router(%Context{schema: schema, context_app: ctx_app} = context) do
    web_path = Mix.Mandarin.web_path(ctx_app)
    router_path = Path.join(web_path, "router.ex")

    if File.exists?(router_path) do
      # Generate the code we'll inject:
      pipeline_and_scope = new_pipeline_and_scope(context)

      # We should only add the pipeline and scope to the router if they don't exist already.
      # To detect whether they already exist, we will match the first non-empty line in the injected code.
      # Hopefully that line will be unique enough for our purposes.

      # Get the first non-empty line of the injected code
      pipeline_start =
        pipeline_and_scope
        |> String.trim_leading()
        |> String.split("\n")
        |> Enum.at(0)
        |> String.trim()

      # Only inject the code if the file doesn't contain the start of the pipeline
      router_contents = File.read!(router_path)

      code_after_pipeline_injection =
        if String.contains?(router_contents, pipeline_start) do
          Mix.shell().info("""
          Mandarin didn't inject a pipeline and scope for the curent context because they already exist.
          """)

          # The router contents remain the same
          router_contents
        else
          # This will always succed because we've checked the route and pipeline don't exist
          {:ok, new_code} = Injector.inject_before_final_end(router_contents, pipeline_and_scope)

          # The router contents have been updated
          new_code
        end

      # In any case, the correct scope already exists in the router.ex file at this point.
      # We can inject the resource routes inside the scope.

      routes_injection_point = "# %% Mandarin Routes - #{inspect(context.web_module)}.#{inspect(context.alias)} %%"

      routes_to_inject = """
          # Routes for #{schema.human_plural}
          live "/#{schema.plural}", #{inspect(schema.alias)}LiveBrowse
          live "/#{schema.plural}/new", #{inspect(schema.alias)}LiveEdit
          live "/#{schema.plural}/:id", #{inspect(schema.alias)}LiveShow
          live "/#{schema.plural}/:id/edit", #{inspect(schema.alias)}LiveEdit
      """

      code_after_routes_injection =
        case Injector.inject_after(code_after_pipeline_injection, routes_injection_point, routes_to_inject) do
          {:ok, new_code} ->
            Mix.shell().info("""

            Mandarin has added the resource to your #{schema.web_namespace} :#{context.basename} scope in #{Mix.Mandarin.web_path(ctx_app)}/router.ex:

                scope "/#{schema.web_path}", #{inspect(Module.concat(context.web_module, schema.web_namespace))}, as: :#{schema.web_path} do
                  pipe_through([:browser, :#{context.basename}_layout])
                  ...
                  get "/#{context.basename}/#{schema.plural}/select", #{inspect(schema.alias)}Controller
                  resources "/#{context.basename}/#{schema.plural}", #{inspect(schema.alias)}Controller
                end
            """)

            new_code

          :error ->
            Mix.shell().info("""
            Mandarin was unable to inject new routes into the "#{router_path}" file.
            Please ensure that the following line exists in the scope:

                #{routes_injection_point}

            If the line above exists, then mandarin will be able to automatically inject routes
            """)

            code_after_pipeline_injection
        end

      File.write!(router_path, code_after_routes_injection)
    else
      Mix.shell().info("""
      No "#{router_path}" file was found.
      """)
    end
  end


  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    if schema.web_namespace do
      Mix.shell().info("""

      Mandarin has added the resource to your #{schema.web_namespace} :#{context.basename} scope in #{Mix.Mandarin.web_path(ctx_app)}/router.ex:

          scope "/#{schema.web_path}", #{inspect(Module.concat(context.web_module, schema.web_namespace))}, as: :#{schema.web_path} do
            pipe_through([:browser, :#{context.basename}_layout])
            ...
            get "/#{context.basename}/#{schema.plural}/select", #{inspect(schema.alias)}Controller
            resources "/#{context.basename}/#{schema.plural}", #{inspect(schema.alias)}Controller
          end
      """)
    else
      Mix.shell().info("""

      Add the resource to your browser scope in #{Mix.Mandarin.web_path(ctx_app)}/router.ex:
      """)
    end

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end

  defp input_for_attr(schema, attr) do
    case attr do
      {key, :integer} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="number" label="#{label(key)}" />)

      {key, :float} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="number" label="#{label(key)}" step="any" />)

      {key, :decimal} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="number" label="#{label(key)}" step="any" />)

      {key, :boolean} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="checkbox" label="#{label(key)}" />)

      {key, :text} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="text" label="#{label(key)}" />)

      {key, :date} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="date" label="#{label(key)}" />)

      {key, :time} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="time" label="#{label(key)}" />)

      {key, :utc_datetime} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="datetime-local" label="#{label(key)}" />)

      {key, :naive_datetime} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="datetime-local" label="#{label(key)}" />)

      {key, {:array, _} = type} ->
        ~s"""
        <.input
          field={@form[#{inspect(key)}]}
          type="select"
          multiple
          label="#{label(key)}"
          options={#{inspect(default_options(type))}}
        />
        """

      {key, {:enum, _}} ->
        ~s"""
        <.input
          field={@form[#{inspect(key)}]}
          type="select"
          label="#{label(key)}"
          prompt="Choose a value"
          options={Ecto.Enum.values(#{inspect(schema.module)}, #{inspect(key)})}
        />
        """

      {key, _} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="text" label="#{label(key)}" />)
    end
  end

  defp input_for_assoc({key, _key_id, _module, _source} = _assoc) do
    ~s(<.input type="select" field={@form[:#{key}_id]} label="#{label(key)}" options={@#{key}_options}/>)
  end

  @doc false
  def inputs(%Schema{} = schema) do
    assoc_inputs = Enum.map(schema.assocs, &input_for_assoc/1)

    attr_inputs =
      schema.attrs
      |> Enum.reject(fn {_key, type} -> type == :map end)
      |> Enum.map(fn attr -> input_for_attr(schema, attr) end)

    assoc_inputs ++ attr_inputs
  end

  defp default_options({:array, :string}),
    do: Enum.map([1, 2], &{"Option #{&1}", "option#{&1}"})

  defp default_options({:array, :integer}),
    do: Enum.map([1, 2], &{"#{&1}", &1})

  defp default_options({:array, _}), do: []

  defp label(key), do: Mandarin.Naming.humanize(to_string(key))

  @doc false
  def indent_inputs(inputs, column_padding) do
    columns = String.duplicate(" ", column_padding)

    inputs
    |> Enum.map(fn input ->
      lines = input |> String.split("\n") |> Enum.reject(&(&1 == ""))

      case lines do
        [] ->
          []

        [line] ->
          [columns, line]

        [first_line | rest] ->
          rest = Enum.map_join(rest, "\n", &(columns <> &1))
          [columns, first_line, "\n", rest]
      end
    end)
    |> Enum.intersperse("\n")
  end
end
