
  alias <%= inspect schema.module %>

  # By default, we preload all associations.
  @<%= schema.singular %>_preloads [<%=
      schema.assocs
      |> Enum.map(fn {key, _, _, _} -> inspect(key) end)
      |> Enum.intersperse(", ")
    %>]

  @doc """
  Returns the list of <%= schema.plural %>.

  Be careful as this will attempt to load the full database table into memory.
  If you want results to be paginated you should use
  the `list_<%= schema.plural %>/1` function instead.

  ## Examples

      iex> list_<%= schema.plural %>()
      [%<%= inspect schema.alias %>{}, ...]

  """
  def list_all_<%= schema.plural %> do
    <%= inspect schema.alias %>
    |> Repo.all()
    |> Repo.preload(@<%= schema.singular %>_preloads)
  end

  @doc """
  Returns the list of <%= schema.plural %> paginated according to the given `params`.

  ## Examples

      iex> list_<%= schema.plural %>(params)
      {:ok, {[%<%= inspect schema.alias %>{}, ...], %Flop.Meta{}}}

  """
  def list_<%= schema.plural %>(params) do
    # If no page size was given, use the default
    params = Map.put_new(params, "page_size", 25)

    {:ok, {<%= schema.plural %>, meta}} =
      Flop.validate_and_run(<%= inspect schema.alias %>, params,
        for: <%= inspect schema.alias %>,
        repo: Repo
      )

    <%= schema.plural %> = Repo.preload(<%= schema.plural %>, @<%= schema.singular %>_preloads)

    {:ok, {<%= schema.plural %>, meta}}
  end

  @doc """

  """
  def list_<%= schema.plural %>_as_options(params \\ %{}) do
    # No default page size; if you're using this we assume you
    # have paginated everything correctly already.
    # We won't silently paginate because the UI doesn't have
    # a way of showing whether everything has been shown or
    # whether there are resources behind the first page.
    {:ok, {<%= schema.plural %>, _meta}} =
      Flop.validate_and_run(<%= inspect schema.alias %>, params,
        for: <%= inspect schema.alias %>,
        repo: Repo
      )

    Bootstrap5Components.as_select_options(<%= schema.plural %>)
  end

  @doc """
  Runs a search query on <%= schema.plural %>.

  ## Examples

      iex> search_<%= schema.plural %>(text)
      %{results: [...], more: true}

  """<%= if schema.search_field do %>
  def search_<%= schema.plural %>(text) do
    # Match any substring
    query_string = "%#{text}%"

    Repo.all(
      from <%= schema.singular %> in <%= inspect schema.alias %>,
        where: ilike(<%= schema.singular %>.<%= schema.search_field %>, ^query_string),
        limit: 15
    )
  end<% else %>
  def search_<%= schema.plural %>(_params) do
    # Implement a custom way of searching <%= schema.plural %>
    raise UndefinedFunctionError, "<%= inspect schema.alias %> doesn't have a string field that can be used for search"
  end<% end %>


  @doc """
  Gets a single <%= schema.singular %>.

  Raises `Ecto.NoResultsError` if the <%= schema.human_singular %> does not exist.

  ## Examples

      iex> get_<%= schema.singular %>!(123)
      %<%= inspect schema.alias %>{}

      iex> get_<%= schema.singular %>!(456)
      ** (Ecto.NoResultsError)

  """
  def get_<%= schema.singular %>!(id) do
    <%= inspect schema.alias %>
    |> Repo.get!(id)
    |> Repo.preload(@<%= schema.singular %>_preloads)
  end

  @doc """
  Creates a <%= schema.singular %>.

  ## Examples

      iex> create_<%= schema.singular %>(%{field: value})
      {:ok, %<%= inspect schema.alias %>{}}

      iex> create_<%= schema.singular %>(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_<%= schema.singular %>(attrs \\ %{}) do
    %<%= inspect schema.alias %>{}
    |> Repo.preload(@<%= schema.singular %>_preloads)
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a new <%= schema.singular %>.

  ## Examples

      iex> new_<%= schema.singular %>()
      %<%= inspect schema.alias %>{}

  """
  def new_<%= schema.singular %>() do
    Repo.preload(%<%= inspect schema.alias %>{}, @<%= schema.singular %>_preloads)
  end

  @doc """
  Updates a <%= schema.singular %>.

  ## Examples

      iex> update_<%= schema.singular %>(<%= schema.singular %>, %{field: new_value})
      {:ok, %<%= inspect schema.alias %>{}}

      iex> update_<%= schema.singular %>(<%= schema.singular %>, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> Repo.preload(@<%= schema.singular %>_preloads)
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a <%= schema.singular %>.

  ## Examples

      iex> delete_<%= schema.singular %>(<%= schema.singular %>)
      {:ok, %<%= inspect schema.alias %>{}}

      iex> delete_<%= schema.singular %>(<%= schema.singular %>)
      {:error, %Ecto.Changeset{}}

  """
  def delete_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    Repo.delete(<%= schema.singular %>)
  end

  @doc """
  Deletes <%= schema.plural %> in bulk.

  ## Examples

      iex> bulk_delete_<%= schema.plural %>(<%= schema.singular %>)
      {nr_deleted, result}
  """
  def bulk_delete_<%= schema.plural %>(<%= schema.singular %>_ids) do
    Repo.delete_all(
      from <%= schema.singular %> in <%= inspect schema.alias %>,
        where: <%= schema.singular %>.id in ^<%= schema.singular %>_ids
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking <%= schema.singular %> changes.

  ## Examples

      iex> change_<%= schema.singular %>(<%= schema.singular %>)
      %Ecto.Changeset{data: %<%= inspect schema.alias %>{}}

  """
  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, attrs)
  end

  # --------------------------------------------------------
  # Authorization checks (used by the controllers)
  # --------------------------------------------------------

  @doc """
  Checks for whether the user can browse <%= schema.plural %>.
  """
  @spec can_browse_<%= schema.plural %>(maybe_user()) :: authz_result()
  def can_browse_<%= schema.plural %>(user) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end

  @doc """
  Checks for whether the user can read the given <%= schema.singular %>.
  """
  @spec can_read_<%= schema.singular %>(maybe_user(), <%= inspect(schema.alias) %>.t()) :: authz_result()
  def can_read_<%= schema.singular %>(user, _<%= schema.singular %>) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end

  @doc """
  Checks for whether the user can browse <%= schema.plural %>.
  """
  @spec can_edit_<%= schema.singular %>(maybe_user(), <%= inspect(schema.alias) %>.t()) :: authz_result()
  def can_edit_<%= schema.singular %>(user, _<%= schema.singular %>) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end

  @doc """
  Checks for whether the user can add a new <%= schema.singular %>.
  """
  @spec can_create_<%= schema.singular %>(maybe_user()) :: authz_result()
  def can_create_<%= schema.singular %>(user) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end

  @doc """
  Checks for whether the user can delete the given <%= schema.singular %>.
  """
  @spec can_delete_<%= schema.singular %>(maybe_user(), <%= inspect(schema.alias) %>.t()) :: authz_result()
  def can_delete_<%= schema.singular %>(user, _<%= schema.singular %>) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end

  @doc """
  Checks for whether the user can delete the <%= schema.human_plural %>
  in bulk given their IDs.
  """
  @spec can_bulk_delete_<%= schema.plural %>(maybe_user(), list()) :: authz_result()
  def can_bulk_delete_<%= schema.plural %>(user, _<%= schema.singular %>_ids) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end

  @doc """
  Checks for whether the user can browse <%= schema.plural %>.
  """
  @spec can_export_<%= schema.plural %>(maybe_user(), <%= inspect(schema.alias) %>.t()) :: authz_result()
  def can_export_<%= schema.plural %>(user, _<%= schema.singular %>) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end
