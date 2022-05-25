defmodule Mix.Mandarin.Context do
  @moduledoc false

  alias Mandarin.Naming
  alias Mix.Mandarin.{Context, Schema}

  defstruct name: nil,
            module: nil,
            schema: nil,
            alias: nil,
            base_module: nil,
            mandarin_web_module: nil,
            web_module: nil,
            basename: nil,
            file: nil,
            test_file: nil,
            test_fixtures_file: nil,
            dir: nil,
            generate?: true,
            context_app: nil,
            quiet: nil,
            yes: nil,
            opts: []

  def valid?(context) do
    context =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def new(context_name, %Schema{} = schema \\ %Schema{}, opts) do
    ctx_app = opts[:context_app] || Mix.Mandarin.context_app()
    mandarin_web_module_as_string = Naming.mandarin_web_module(ctx_app)
    mandarin_web_module = Module.concat([mandarin_web_module_as_string])
    base = Module.concat([Mix.Mandarin.context_base(ctx_app)])
    module = Module.concat(base, context_name)
    alias = Module.concat([module |> Module.split() |> List.last()])
    basedir = Mandarin.Naming.underscore(context_name)
    basename = Path.basename(basedir)
    dir = Mix.Mandarin.context_lib_path(ctx_app, basedir)
    # Add an underscore before the basename so that the context module
    # is the first in alphabetical order. It makes the context vs changeset
    # hierarchy easier to visualize.
    file = Path.join([dir, "_" <> basename <> ".ex"])

    test_dir = Mix.Mandarin.context_test_path(ctx_app, basedir)
    test_file = Path.join([test_dir, basename <> "_test.exs"])
    test_fixtures_dir = Mix.Mandarin.context_app_path(ctx_app, "test/support/fixtures")
    test_fixtures_file = Path.join([test_fixtures_dir, basedir <> "_fixtures.ex"])

    generate? = Keyword.get(opts, :context, true)

    %Context{
      name: context_name,
      module: module,
      schema: schema,
      alias: alias,
      base_module: base,
      web_module: web_module(),
      mandarin_web_module: mandarin_web_module,
      basename: basename,
      file: file,
      test_file: test_file,
      test_fixtures_file: test_fixtures_file,
      dir: dir,
      generate?: generate?,
      context_app: ctx_app,
      opts: opts
    }
  end

  def pre_existing?(%Context{file: file}), do: File.exists?(file)

  def pre_existing_tests?(%Context{test_file: file}), do: File.exists?(file)

  def pre_existing_test_fixtures?(%Context{test_fixtures_file: file}), do: File.exists?(file)

  def function_count(%Context{file: file}) do
    {_ast, count} =
      file
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.postwalk(0, fn
        {:def, _, _} = node, count -> {node, count + 1}
        node, count -> {node, count}
      end)

    count
  end

  def file_count(%Context{dir: dir}) do
    dir
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.count()
  end

  defp web_module do
    base = Mix.Mandarin.base()

    cond do
      Mix.Mandarin.context_app() != Mix.Mandarin.otp_app() ->
        Module.concat([base])

      String.ends_with?(base, "Web") ->
        Module.concat([base])

      true ->
        Module.concat(["#{base}Web"])
    end
  end
end
