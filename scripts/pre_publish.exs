defmodule PrePublish do
  @mix_path "mix.exs"
  @readme_path "README.md"
  @changelog_path "CHANGELOG.md"
  @changes_marker "<!-- changes - write changes below -->"

  def run() do
    version_type_string = version_type_from_user_input!()
    version_type = parse_version_type(version_type_string)

    Mix.Shell.IO.info(">>> Run tests")
    {_message, code} = System.shell("MIX_ENV=test mix test", into: IO.stream())

    if code == 0 do
      Mix.Shell.IO.info(">>> Bump version")
      new_version = bump_version_in_file(@mix_path, version_type)
      replace_dependency_version_in_readme(@readme_path, new_version)

      Mix.Shell.IO.info(">>> Add new title to CHANGELOG.md")
      update_changelog(@changelog_path, new_version)

      Mix.Shell.IO.info(">>> Run git commands")
      git_commands(new_version)

      Mix.Shell.IO.info(">>> You must invoke 'mix hex.publish' manually")
    else
      Mix.Shell.IO.error("Can't publish because some tests fail")
    end
  end

  def otp_app() do
    Mix.Project.config() |> Keyword.fetch!(:app)
  end

  def version_type_from_user_input!() do
    case System.argv() do
      [version_type_string] ->
        version_type_string

      [] ->
        raise ArgumentError, """
          No arguments given. Requires a version type ('major', 'minor', or 'patch').
          """

      _other ->
        raise ArgumentError, """
          Requires a single argument corresponding to a version type \
          ('major', 'minor', or 'patch').
          """
    end
  end

  def replace_dependency_version_in_readme(readme_path, new_version) do
    content = File.read!(readme_path)

    new_content =
      Regex.replace(~r/\{#{inspect(otp_app())}\s*,\s+"~>\s+(\d+\.\d+\.\d+)"/, content, fn _string, _old_vsn ->
        "\{#{inspect(otp_app())}, \"~> #{Version.to_string(new_version)}\""
      end)

    File.write!(readme_path, new_content)
  end

  def get_version(content) do
    case Regex.named_captures(~r/@version\s+\"(?<version>\d+\.\d+\.\d+)\"\n/, content) do
      %{"version" => version_string} ->
        _version = Version.parse!(version_string)

      _other ->
        raise "Couldn't parse version from 'mix.exs' file."
    end
  end

  def update_version(content, new_version) do
    Regex.replace(~r/@version\s+"(\d+\.\d+\.\d+)"\n/, content, fn _string, _old_vsn ->
      "@version \"#{Version.to_string(new_version)}\"\n"
    end)
  end

  def bump_version(version, type) do
    case type do
      :major -> %{version | major: version.major + 1}
      :minor -> %{version | minor: version.minor + 1}
      :patch -> %{version | patch: version.patch + 1}
    end
  end

  def parse_version_type(version_type_string) do
    case version_type_string do
      "major" -> :major
      "minor" -> :minor
      "patch" -> :patch
      _other ->
        raise """
          Invalid version type #{inspect(version_type_string)}. \
          Valid values are: "major", "minor" or "patch"
          """
    end
  end

  def bump_version_in_file(path, type) do
    content = File.read!(path)
    version = get_version(content)
    new_version = bump_version(version, type)
    updated_content = update_version(content, new_version)
    File.write!(path, updated_content)
    new_version
  end

  def update_changelog(path, new_version) do
    content = File.read!(path)
    version_string = Version.to_string(new_version)

    date_time_string =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> NaiveDateTime.to_string()

    if content =~ @changes_marker do
      new_title = @changes_marker <> "\n\n## v#{version_string} - #{date_time_string}\n"
      new_content = String.replace(content, @changes_marker, new_title)
      File.write!(path, new_content)
    else
      raise "CHANGELOG.md must contain the line '<!-- changes - write changes below -->'"
    end
  end

  def git_commands(new_version) do
    version_string = Version.to_string(new_version)
    System.shell(~s[git add .])
    System.shell(~s[git commit -m "bump version number to v#{version_string}"])
    System.shell(~s[git tag -a "v#{version_string}" -m "Add v#{version_string} tag"])
    System.shell(~s[git push -u origin])
  end
end

PrePublish.run()
