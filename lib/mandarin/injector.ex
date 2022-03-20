defmodule Mandarin.Injector do
  @moduledoc false

  @type text_injection_result ::
          {:ok, String.t()}
          | {:marker_not_found, String.t()}
          | {:already_injected, String.t()}

  @type file_injection_result :: :ok | :marker_not_found | :already_injected

  def inject_before_final_end(content_to_inject, file_path) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      content =
        file
        |> String.trim_trailing()
        |> String.trim_trailing("end")
        |> Kernel.<>(content_to_inject)
        |> Kernel.<>("end\n")

      formatted_content = maybe_format_code(content, file_path)

      File.write!(file_path, formatted_content)
    end
  end

  defp with_skip_marker(path, opts, fun) do
    case Keyword.fetch(opts, :skip_marker) do
      {:ok, marker} ->
        content = File.read!(path)
        if String.contains?(content, marker) do
          :skip
        else
          fun.(content)
        end

      :error ->
        path |> File.read!() |> fun.()
    end
  end

  @doc """
  Reads the contents of a file and injects the text below the given marker.
  Logs a warning if the marker wasn't found in the file.
  """
  @spec inject_below_in_file(Path.t(), String.t(), String.t(), Keyword.t()) :: file_injection_result()
  def inject_below_in_file(file, marker, injected, opts \\ []) do
    with_skip_marker(file, opts, fn content ->
      content
      |> inject_below_in_text(marker, injected)
      |> update_file_if_marker_was_found(file, marker)
    end)
  end

  @doc """
  Reads the contents of a file and injects the text above the given marker.
  Logs a warning if the marker wasn't found in the file.
  """
  @spec inject_below_in_file(Path.t(), String.t(), String.t()) :: file_injection_result()
  def inject_above_in_file(file, marker, injected) do
    file
    |> File.read!()
    |> inject_below_in_text(marker, injected)
    |> update_file_if_marker_was_found(file, marker)
  end

  @doc """
  Injects text below a marker.
  The injected text will be indented as much as the marker.
  """
  @spec inject_below_in_text(String.t(), String.t(), String.t()) :: text_injection_result()
  def inject_below_in_text(text, marker, injected) do
    generic_inject_in_text(
      text,
      marker,
      injected,
      fn above, middle, indented_injected, below ->
        # Be careful when handling newlines!
        # a newline is needed after `indente_injected` but not before.
        to_string([above, middle, indented_injected, "\n", below])
      end
    )
  end

  @doc """
  Injects text above a marker.
  The injected text will be indented as much as the marker.
  """
  @spec inject_above_in_text(String.t(), String.t(), String.t()) :: text_injection_result()
  def inject_above_in_text(text, marker, injected) do
    generic_inject_in_text(
      text,
      marker,
      injected,
      fn above, middle, indented_injected, below ->
        # Be careful when handling newlines!
        # a newline is needed before `indente_injected` but not after.
        to_string([above, "\n", indented_injected, middle, below])
      end
    )
  end

  @spec update_file_if_marker_was_found(text_injection_result(), Path.t(), String.t()) ::
          file_injection_result()
  defp update_file_if_marker_was_found(result, file, _marker) do
    case result do
      {:ok, content} ->
        formatted_content = maybe_format_code(content, file)
        File.write!(file, formatted_content)
        :ok

      {:marker_not_found, _content} ->
        :marker_not_found

      {:already_injected, _content} ->
        :already_injected
    end
  end

  defp generic_inject_in_text(text, marker, injected, transformer) do
    text_unix = to_unix_line_endings(text)
    escaped_marker = Regex.escape(marker)
    regex = Regex.compile!("\n(\s*)(#{escaped_marker}\n)")

    case Regex.split(regex, text_unix, include_captures: true, parts: 2) do
      [above, middle, below] ->
        [_full_string, leading_whitespace] = Regex.run(~r/\n(\s*)/, middle)
        indented_injected = indent_text(injected, leading_whitespace)

        case String.contains?(text, indented_injected) do
          true ->
            {:already_injected, text}

          false ->
            new_text = transformer.(above, middle, indented_injected, below)
            {:ok, new_text}
        end

      _ ->
        {:marker_not_found, text_unix}
    end
  end

  @spec to_unix_line_endings(String.t()) :: String.t()
  defp to_unix_line_endings(text) do
    String.replace(text, "\r\n", "\n")
  end

  @spec indent_text(String.t(), String.t()) :: String.t()
  defp indent_text(text, indentation_whitespace) do
    lines = String.split(text, "\n")
    indented_lines = Enum.map(lines, fn line -> [indentation_whitespace, line] end)
    indented_lines |> Enum.intersperse("\n") |> to_string()
  end

  @spec maybe_format_code(String.t(), Path.t()) :: String.t()
  defp maybe_format_code(text, file_name) do
    if String.ends_with?(file_name, ".ex") or String.ends_with?(file_name, ".exs") do
      Code.format_string!(text) |> to_string()
    else
      text |> to_string()
    end
  end

  @spec write_file(String.t(), Path.t()) :: :ok
  def write_file(content, file) do
    File.write!(file, content)
  end
end
