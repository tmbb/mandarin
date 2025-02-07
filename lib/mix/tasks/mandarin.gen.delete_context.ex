defmodule Mix.Tasks.Mandarin.Gen.DeleteContext do
  @shortdoc "Generates a context with functions around an Ecto schema"

  @moduledoc """
  Generates a context with functions around an Ecto schema.

      $ mix mandarin.gen.context Accounts User users name:string age:integer

  The first argument is the context module followed by the schema module
  and its plural name (used as the schema table name).

  The context is an Elixir module that serves as an API boundary for
  the given resource. A context often holds many related resources.
  Therefore, if the context already exists, it will be augmented with
  functions for the given resource.

  > Note: A resource may also be split
  > over distinct contexts (such as Accounts.User and Payments.User).

  The schema is responsible for mapping the database fields into an
  Elixir struct.

  Overall, this generator will add the following files to `lib/your_app`:

    * a context module in `accounts.ex`, serving as the API boundary
    * a schema in `accounts/user.ex`, with a `users` table

  A migration file for the repository and test files for the context
  will also be generated.

  ## Generating without a schema

  In some cases, you may wish to bootstrap the context module and
  tests, but leave internal implementation of the context and schema
  to yourself. Use the `--no-schema` flags to accomplish this.

  ## table

  By default, the table name for the migration and schema will be
  the plural name provided for the resource. To customize this value,
  a `--table` option may be provided. For example:

      $ mix mandarin.gen.context Accounts User users --table cms_users

  ## binary_id

  Generated migration can use `binary_id` for schema's primary key
  and its references with option `--binary-id`.

  ## Default options

  This generator uses default options provided in the `:generators`
  configuration of your application. These are the defaults:

      config :your_app, :generators,
        migration: true,
        binary_id: false,
        timestamp_type: :naive_datetime,
        sample_binary_id: "11111111-1111-1111-1111-111111111111"

  You can override those options per invocation by providing corresponding
  switches, e.g. `--no-binary-id` to use normal ids despite the default
  configuration or `--migration` to force generation of the migration.

  Read the documentation for `mandarin.gen.schema` for more information on
  attributes.

  ## Skipping prompts

  This generator will prompt you if there is an existing context with the same
  name, in order to provide more instructions on how to correctly use phoenix contexts.
  You can skip this prompt and automatically merge the new schema access functions and tests into the
  existing context using `--merge-with-existing-context`. To prevent changes to
  the existing context and exit the generator, use `--no-merge-with-existing-context`.
  """

  use Mix.Task

  require Logger

  alias Mix.Mandarin.{Context, Schema}
  alias Mix.Tasks.Mandarin.Gen

  @migrations_path "priv/repo/migrations"

  @switches [
    binary_id: :boolean,
    table: :string,
    web: :string,
    schema: :boolean,
    context: :boolean,
    context_app: :string,
    merge_with_existing_context: :boolean,
    prefix: :string,
    live: :boolean
  ]

  @default_opts [schema: true, context: true]

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix mandarin.gen.delete_context must be invoked from within your *_web application root directory"
      )
    end

    # Fake schema to reuse more of the existing machinery.
    # We'll ignore the schema.
    # TODO: clean this up later
    fake_args = args ++ [
      "MyStupidDummySchema",
      "my_stupid_dummy_schemas",
      "xxx:string"
    ]

    {context, _schema} = build(fake_args)

    web_path = Mix.Mandarin.web_path(context.context_app)
    router_path = Path.join(web_path, "router.ex")
    web_context_dir = Path.join(web_path, context.basename)

    web_context_test_dir =
      context.context_app
      |> Mix.Mandarin.web_test_path()
      |> Path.join(context.basename)

    rm_if_exists!(context.file)
    rm_if_exists!(context.test_file)
    rm_if_exists!(context.test_fixtures_file)

    rm_rf_if_exists!(context.dir)
    rm_rf_if_exists!(context.dir)
    rm_rf_if_exists!(web_context_dir)
    rm_rf_if_exists!(web_context_test_dir)

    drop_migrations_if_already_exist(context.basename)

    remove_code_from_router(context.basename, router_path)

    :ok
  end

  defp rm_if_exists!(path) do
    if File.exists?(path) do
      File.rm!(path)
    end
  end

  defp rm_rf_if_exists!(path) do
    if File.exists?(path) do
      File.rm_rf!(path)
    end
  end

  def remove_code_from_router(context_basename, router_path) do
    # Build Sourceror literals out of code blocks
    scope_route = "/#{context_basename}"
    # Despite generating atoms at runtime, this is safe because
    # the generator will only run at "dev time".
    context_layout = :"#{context_basename}_layout"

    source = File.read!(router_path)

    {_quoted, patches} =
      source
      |> Sourceror.parse_string!()
      |> Macro.postwalk([], fn
        {:pipeline, _meta, [{:__block__, _block_meta, [^context_layout]} | _other]} = quoted, patches ->
          range = Sourceror.get_range(quoted)

          patch = %{range: range, change: ""}
          {quoted, [patch | patches]}

        {:scope, _meta, [{:__block__, _block_meta, [^scope_route]} | _other]} = quoted, patches ->
          range = Sourceror.get_range(quoted)

          patch = %{range: range, change: ""}
          {quoted, [patch | patches]}

        quoted, patches ->
          {quoted, patches}
      end)

    new_source = Sourceror.patch_string(source, patches)

    # Write the file (without using the formatter)
    File.write!(router_path, new_source)
    # Format the file using the mix task so that it respects
    # project-wide settings (in the 'formatter.exs' file)
    Mix.Tasks.Format.run([router_path])

    :ok
  end

  def drop_migrations_if_already_exist(migration_path \\ @migrations_path, tag) when tag != "" do
    files = File.ls!(migration_path)
    substring = "__#{tag}__.txt"
    markers = Enum.filter(files, fn file -> String.ends_with?(file, substring) end)

    case check_exactly_2_markers(markers) do
      :error ->
        :error

      :ok ->
        # We have exactly two markers
        [m1, m2] = markers

        marker_low = min(m1, m2)
        marker_high = max(m1, m2)

        files_to_delete =
          Enum.filter(files, fn file ->
            file >= marker_low and file <= marker_high
          end)

        Enum.map(files_to_delete, fn file -> File.rm!(Path.join(migration_path, file)) end)

        :ok
    end
  end

  defp check_exactly_2_markers(markers) do
    case length(markers) do
      0 ->
        Logger.warning("""
        drop_migrations/2 expects exactly 2 marker files with the given tag; no markers were found
        """)

        :error

      1 ->
        Logger.warning("""
        drop_migrations/2 expects exactly 2 marker files with the given tag; only 1 marker was found
        """)

        :error

      2 ->
        :ok

      n ->
        Logger.warning("""
        drop_migrations/2 expects exactly 2 marker files with the given tag; #{n} markers were found
        """)

        :error
    end
  end

  @doc false
  def build(args, help \\ __MODULE__) do
    {opts, parsed, _} = parse_opts(args)

    [context_name, schema_name, plural | schema_args] = validate_args!(parsed, help)
    schema_module = inspect(Module.concat(context_name, schema_name))
    opts = Keyword.put_new(opts, :web, context_name)

    schema = Gen.Schema.build([schema_module, plural | schema_args], opts, help)
    context = Context.new(context_name, %Schema{}, opts)

    {context, schema}
  end

  defp parse_opts(args) do
    {opts, parsed, invalid} = OptionParser.parse(args, switches: @switches)

    merged_opts =
      @default_opts
      |> Keyword.merge(opts)
      |> put_context_app(opts[:context_app])

    {merged_opts, parsed, invalid}
  end

  defp put_context_app(opts, nil), do: opts

  defp put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  @doc false
  def files_to_be_generated(%Context{schema: schema}) do
    if schema.generate? do
      Gen.Schema.files_to_be_generated(schema)
    else
      []
    end
  end

  defp validate_args!([context | _rest] = args, help) do
    cond do
      not Context.valid?(context) ->
        help.raise_with_help(
          "Expected the context, #{inspect(context)}, to be a valid module name"
        )

      true ->
        args
    end
  end

  defp validate_args!(_, help) do
    help.raise_with_help("Invalid arguments")
  end

  @doc false
  def raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix mandarin.gen.delete_context expects a single context name.
    """)
  end

  @doc false
  def prompt_for_code_injection(%Context{generate?: false}), do: :ok

  def prompt_for_code_injection(%Context{} = context) do
    if Context.pre_existing?(context) && !merge_with_existing_context?(context) do
      System.halt()
    end
  end

  defp merge_with_existing_context?(%Context{} = context) do
    Keyword.get_lazy(context.opts, :merge_with_existing_context, fn ->
      function_count = Context.function_count(context)
      file_count = Context.file_count(context)

      Mix.shell().info("""
      You are generating into an existing context.

      The #{inspect(context.module)} context currently has #{singularize(function_count, "functions")} and \
      #{singularize(file_count, "files")} in its directory.

        * It's OK to have multiple resources in the same context as \
      long as they are closely related. But if a context grows too \
      large, consider breaking it apart

        * If they are not closely related, another context probably works better

      The fact two entities are related in the database does not mean they belong \
      to the same context.

      If you are not sure, prefer creating a new context over adding to the existing one.
      """)

      Mix.shell().yes?("Would you like to proceed?")
    end)
  end

  defp singularize(1, plural), do: "1 " <> String.trim_trailing(plural, "s")
  defp singularize(amount, plural), do: "#{amount} #{plural}"
end
