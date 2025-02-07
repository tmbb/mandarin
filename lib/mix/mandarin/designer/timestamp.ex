defmodule Mandarin.Designer.Timestamp do
  @moduledoc false

  # This module exists as a hack to ensure we have monotonically increasing timestamps
  # for ecto migrations. The ecto generators (which Phoenix and Mandarin use)
  # generate timestamps with a granularity of a second.
  # This is enough if the user is manually running the generators one by one,
  # but it's not enough if we're using the generators programmatcally.
  #
  # If we're running the generators programmatically we can generate
  # a new migration table in microseconds or milliseconds, and thus the
  # timestamps will be the same. This will breake the ecto migration system.
  #
  # This module provides functions to read the timestamps already present
  # in the migrations directory. If the current timestamp is equal to one of
  # those timestamps, the functions in this module will return the next timestamp
  # with the granularity of a second.

  require ExUnit.Assertions, as: Assertions
  require Logger

  @timestamp_regex Regex.compile!("^(" <> String.duplicate("\\d", 14) <> ")_")

  def with_timestamp_update_if_needed(dir, fun) do
    # Get the state of the directory before running the function
    old_filenames = File.ls!(dir)
    # Run the function
    fun.()
    # The function has presumably created a new file
    new_filenames = File.ls!(dir)
    # Now we want to rename the new file´
    case find_old_and_new_filename(old_filenames, new_filenames) do
      {:ok, {to_rename, renamed}} ->
        # Absolute path of old filename
        abs_path_to_rename = Path.join(dir, to_rename)
        # Absolute path of the new filename
        abs_path_renamed = Path.join(dir, renamed)
        # Rename the file
        File.rename!(abs_path_to_rename, abs_path_renamed)
        # Return the renamed file
        {:ok, abs_path_renamed}

      :error ->
        :error
    end
  end

  defp find_old_and_new_filename(old_filenames, new_filenames) do
    case find_new_file(old_filenames, new_filenames) do
      {:ok, new_file_before_rename} ->
        new_timestamp = timestamp_for_new_file(old_filenames, new_file_before_rename)
        new_file_after_rename = replace_timestamp(new_file_before_rename, new_timestamp)
        # return the pair of filenames
        {:ok, {new_file_before_rename, new_file_after_rename}}

      :error ->
        :error
    end
  end

  defp timestamp_for_new_file(old_filenames, new_file) do
    current_timestamp_for_new_file = timestamp_for_file(new_file)
    # The new file should already have a timestamp:
    Assertions.assert(current_timestamp_for_new_file != nil)
    highest_timestamp = highest_timestamp_in_filenames(old_filenames)

    # We must deal with three cases:
    cond do
      # The current timestamp is lower than the highest timestamp in the list of files.
      # This should never happen unless you're into time travel or the system clock is doing
      # something funny.
      current_timestamp_for_new_file < highest_timestamp ->
        bump_timestamp(highest_timestamp)

      # The current timestamp is higher than the highest timestamp in the list of files.
      # We can use this timestamp directly.
      current_timestamp_for_new_file > highest_timestamp ->
        current_timestamp_for_new_file

      # Timestamp clashes because of low resolution
      # (timestamps have a resolution of 1 second, while the files can be generated
      # much faster than one per second if we don't have to wait for user confirmation)
      current_timestamp_for_new_file == highest_timestamp ->
        bump_timestamp(current_timestamp_for_new_file)
    end
  end

  defp replace_timestamp(filename, new_timestamp) do
    Assertions.assert(timestamp_for_file(filename) != nil)
    <<_old_timestamp::bytes-size(14)>> <> rest = filename
    new_timestamp <> rest
  end

  def timestamp_for_file(filename) do
    case Regex.run(@timestamp_regex, filename) do
      [_full_match, timestamp] -> timestamp
      nil -> nil
    end
  end

  def group_by_timestamps(filenames) do
    filenames
    |> Enum.group_by(fn filename -> timestamp_for_file(filename) end)
    |> Enum.filter(fn {timestamp, _filenames} -> timestamp != nil end)
  end

  def highest_timestamp_in_filenames(filenames) do
    filenames
    |> Enum.map(&timestamp_for_file/1)
    |> Enum.filter(fn timestamp -> timestamp != nil end)
    # If there are no timestamps, return a "zero" timestamp
    |> Enum.max(fn -> String.duplicate("0", 14) end)
  end

  defp find_new_file(old_filenames, new_filenames) do
    # Turn everything into MapSets to be able to use `MapSet.difference/2`
    old_filenames_set = MapSet.new(old_filenames)
    new_filenames_set = MapSet.new(new_filenames)
    # Get all new files
    delta = MapSet.difference(new_filenames_set, old_filenames_set)
    # We should have either a single new file or no new files.
    # If we have more than one new file, we raise an error:
    case MapSet.to_list(delta) do
      [] ->
        :error

      [new_file] ->
        {:ok, new_file}

      delta_list ->
        raise "Found more than one file: #{inspect(delta_list)}."
    end
  end

  defp bump_timestamp(timestamp_string) do
    timestamp_string
    |> parse_timestamp!()
    |> :calendar.datetime_to_gregorian_seconds()
    |> Kernel.+(1)
    |> :calendar.gregorian_seconds_to_datetime()
    |> print_timestamp()
  end

  def timestamp() do
    :calendar.universal_time() |> print_timestamp()
  end

  def print_timestamp(time) do
    {{y, m, d}, {hh, mm, ss}} = time
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  def parse_timestamp!(<<
        y_s::bytes-size(4),
        m_s::bytes-size(2),
        d_s::bytes-size(2),
        hh_s::bytes-size(2),
        mm_s::bytes-size(2),
        ss_s::bytes-size(2)
      >>) do
    # Convert the binaries into integers...
    y = String.to_integer(y_s)
    m = String.to_integer(m_s)
    d = String.to_integer(d_s)
    hh = String.to_integer(hh_s)
    mm = String.to_integer(mm_s)
    ss = String.to_integer(ss_s)

    # ... and pack them into the format Erlang expects
    {{y, m, d}, {hh, mm, ss}}
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
