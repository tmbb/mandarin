defmodule PhoenixGenStealer do
  @moduledoc """
  Documentation for PhoenixGenStealer.
  """

  @phoenix_url "https://github.com/phoenixframework/phoenix"

  def clone() do
    System.cmd("git", ["clone", @phoenix_url])
  end

  def with_tmp_dir(path, fun) do
    try do
      if File.exists?(path) do
        File.rm_rf!(path)
      end
      File.mkdir_p!(path)
      result = fun.(path)
      File.rm_rf!(path)
      result
    rescue
      e ->
        File.rm_rf!(path)
        raise e
    end
  end

  def rename_files(_pattern, []) do
    :ok
  end

  def rename_files(pattern, [{old, new} | replacements]) do
    # Always recalculate the file list so that we can run multiple passes through a file
    for path <- Path.wildcard(pattern) do
      new_path = String.replace(path, old, new)
      File.rename(path, new_path)
    end
    rename_files(pattern, replacements)
  end

  def replace_in_files(_pattern, []) do
    :ok
  end

  def replace_in_files(pattern, [{old, new} | replacements]) do
    # Always recalculate the file list so that we can run multiple passes through a file
    for path <- Path.wildcard(pattern) do
      if not File.dir?(path) do
        contents = File.read!(path)
        new_contents = String.replace(contents, old, new)
        File.write!(path, new_contents)
      end
    end
    replace_in_files(pattern, replacements)
  end

  def steal(destination, opts \\ []) do
    lowercase = Keyword.fetch!(opts, :lowercase)
    uppercase = Keyword.get(opts, :uppercase, Macro.camelize(lowercase))
    short_lowercase = Keyword.get(opts, :short_lowercase, lowercase)
    short_uppercase = Keyword.get(opts, :short_lowercase, uppercase)
    replacements = [
      {"phoenix", lowercase},
      {"Phoenix", uppercase},
      {"phx", short_lowercase},
      {"Phx", short_uppercase}
    ]

    root = "./_phoenix_tmp_repo"

    with_tmp_dir(root, fn path ->
      {_, 0} = File.cd!(path, fn -> clone() end)
      # Source paths
      mix_src = Path.join([root, "phoenix", "lib", "mix"])
      lib_phoenix_src = Path.join([root, "phoenix", "lib", "phoenix"])
      naming_src = Path.join([lib_phoenix_src, "naming.ex"])
      priv_templates_src = Path.join([root, "phoenix", "priv", "templates"])
      # Destination paths
      mix_dst = Path.join([destination, "lib", "mix"])
      lib_your_app_dst = Path.join([destination, "lib", lowercase])
      naming_dst = Path.join([lib_your_app_dst, "naming.ex"])
      priv_templates_dst = Path.join([destination, "priv", "templates"])
      # Create the destination directories
      File.mkdir_p!(mix_dst)
      File.mkdir_p!(lib_your_app_dst)
      File.mkdir_p!(priv_templates_dst)
      # Copy the files (not yet renamed!)
      File.cp_r!(mix_src, mix_dst)
      File.cp!(naming_src, naming_dst)
      File.cp_r!(priv_templates_src, priv_templates_dst)
      # Process the files
      # We use glob patterns instead of a file list
      # so that each file name can be processed multiple times
      for glob_pattern <- [
        mix_dst <> "/**",
        lib_your_app_dst <> "/**",
        naming_dst <> "**/",
        priv_templates_dst <> "/**"
      ] do
        rename_files(glob_pattern, replacements)
        replace_in_files(glob_pattern, replacements)
      end
    end)

    :ok
  end
end

PhoenixGenStealer.steal(".", lowercase: "bureaucrat")
