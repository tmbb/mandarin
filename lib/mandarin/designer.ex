defmodule Mandarin.Designer do
  @moduledoc """
  Convenience functions to design an application (paramsbase, schemas, contexts and HTML)
  in a programmatic way.

  This is equivalent to using the Phoenix and Mandarin generators, but with a nicer API
  which allows you to use the full power of the Elixir language to run the generators
  instead of relying on custom bash scripts or manually running the generators.
  """

  alias Mandarin.Designer.Params
  alias Mandarin.Designer.Timestamp

  require Logger

  @migrations_path "priv/repo/migrations"

  @migrations_begin_marker_contents """
  # This file marks the BEGINNING of the files generated by EctoDesigner
  """

  @migrations_end_marker_contents """
  # This file marks the END of the files generated by EctoDesigner
  """

  @doc """
  Update the options for a list
  """
  @spec update_options(list(Params.t()), Keyword.t()) :: list(Params.t())
  def update_options(list_of_params, options) do
    options_map = Map.new(options)
    for params <- list_of_params do
      Map.merge(params, options_map)
    end
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
        Logger.warn("""
          drop_migrations/2 expects exactly 2 marker files with the given tag; no markers were found
          """)

        :error
      1 ->
        Logger.warn("""
          drop_migrations/2 expects exactly 2 marker files with the given tag; only 1 marker was found
          """)

        :error

      2 ->
        :ok

      n ->
        Logger.warn("""
          drop_migrations/2 expects exactly 2 marker files with the given tag; #{n} markers were found
          """)

        :error
    end
  end

  @doc """
  Create a foreign key reference
  """
  def references(foreign_table) do
    {:references, foreign_table}
  end

  @doc """
  Tag a field as unique.
  """
  def unique(type) do
    {:unique, type}
  end

  @doc """
  Run a function (`fun`) which may create migration files and add marker files
  to migrations path to delimit which migrations were generated.
  This makes it easier to see which migrations were generated as a group.

  The migration files will contain the `tag` in the file name, so you may want
  to make it descriptive.
  """
  def with_ecto_design_markers(migrations_path \\ @migrations_path, tag, fun) do
    begin_file_name = Path.join(migrations_path, "#{Timestamp.timestamp()}__begin_ecto_designer__#{tag}__.txt")
    Timestamp.with_timestamp_update_if_needed(migrations_path, fn ->
      File.write!(begin_file_name, @migrations_begin_marker_contents)
    end)

    fun.()

    end_file_name = Path.join(migrations_path, "#{Timestamp.timestamp()}__end_ecto_designer__#{tag}__.txt")
    Timestamp.with_timestamp_update_if_needed(migrations_path, fn ->
      File.write!(end_file_name, @migrations_end_marker_contents)
    end)
  end

  # Mandarin generators

  @doc """
  Generate a mandarin schema (without generating a context or any web interface).

  This might be useful for schemas that are meant to act only as `join_through` tables
  for many-to-many relations. These schemas don't require a context or a web interface.
  In fact, the user is not meant to interact with them directly.
  Ecto will be capable of using them when required if the schemas are configured correctly.
  """
  @spec generate_mandarin_schema(String.t(), Params.t()) :: :ok
  def generate_mandarin_schema(migrations_path \\ @migrations_path, params) do
    args = params_to_arguments(params)
    # The schema name is of the form `Context.Schema`
    schema_name = Module.concat(params.context, params.alias) |> inspect()

    Timestamp.with_timestamp_update_if_needed(migrations_path, fn ->
      Mix.Tasks.Mandarin.Gen.Schema.run([schema_name] ++ args)
    end)
    :ok
  end

  @doc """
  Generate a mandarin context (without generating a web interface)
  """
  @spec generate_mandarin_context(String.t(), Params.t()) :: :ok
  def generate_mandarin_context(migrations_path \\ @migrations_path, params) do
    args = params_to_arguments(params)
    context = inspect(params.context)
    name = inspect(params.alias)

    Timestamp.with_timestamp_update_if_needed(migrations_path, fn ->
      Mix.Tasks.Mandarin.Gen.Context.run([context, name] ++ args)
    end)
    :ok
  end

  @doc """
  Generate a mandarin context (without generating a web interface).

  If the params belong to a `join_through` table, this is the same
  as running `generate_mandarin_schema(params)`.
  """
  @spec generate_mandarin_html(String.t(), Params.t()) :: :ok
  def generate_mandarin_html(migrations_path \\ @migrations_path, params) do
    if params.is_join_through? do
      generate_mandarin_schema(migrations_path, params)
    else
      do_generate_mandarin_html(migrations_path, params)
    end
  end

  defp do_generate_mandarin_html(migrations_path, params) do
    args = params_to_arguments(params)
    context = inspect(params.context)
    name = inspect(params.alias)

    Timestamp.with_timestamp_update_if_needed(migrations_path, fn ->
      Mix.Tasks.Mandarin.Gen.Html.run([context, name] ++ args)
    end)
    :ok
  end

  @doc """
  Generate mandarin web interfaces (schemas, context and the web part) for a list of params.

  If the any params belong to a `join_through` table, this will run
  `generate_mandarin_schema(params)` for those params.
  """
  def generate_mandarin_html_for_all(migrations_path \\ @migrations_path, tag, list_of_params) when tag != "" do
    with_ecto_design_markers(tag, fn ->
      for params <- list_of_params do
        generate_mandarin_html(migrations_path, params)
      end
    end)
  end

  @doc """
  Install Mandarin into the given `context`.

  The `context` should be an upper case plural string
  (this function doesn't take a )

  ## Example

      install_mandarin("Admin")

  """
  @spec install_mandarin(String.t()) :: :ok
  def install_mandarin(context) do
    Mix.Tasks.Mandarin.Install.run([context])
    :ok
  end

  # Helpers

  defp make_fields(fields) do
    for {name, value} <- fields do
      string_value =
        case value do
          {:references, table} -> "references:#{table}"
          {:unique, type} -> "#{type}:unique"
          other -> to_string(other)
        end

      "#{name}:#{string_value}"
    end
  end

  defp params_to_arguments(params) do
    # Convert params attributes into arguments that can be given
    # to the phoenix (or vphx/vertical_phoenix) generators
    maybe_binary_id =
      case params.binary_id do
        true -> ["--binary-id"]
        false -> []
      end

    maybe_migration =
      case params.generate_migrations? do
        true -> []
        false -> ["--no-migration"]
      end

    fields = make_fields(params.fields)
    [params.table] ++ maybe_binary_id ++ maybe_migration ++ fields
  end
end