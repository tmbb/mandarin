
  alias <%= inspect schema.module %>

  @<%= schema.singular %>_page_size 25
  @<%= schema.singular %>_search_page_size 15

  # By default, we don't preload any associations,
  # but we centralize the preloaded associations here
  # to make it easier for users to customize them later.
  @<%= schema.singular %>_preloads []

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
    params = Map.put_new(params, :page_size, @<%= schema.singular %>_page_size)
    Flop.validate_and_run(<%= inspect schema.alias %>, params,
      for: <%= inspect schema.alias %>,
      repo: Repo
    )
  end

  @doc """
  Runs a search query on <%= schema.plural %>.

  ## Examples

      iex> search_<%= schema.plural %>(params)
      %{results: [...], more: true}

  """<%= if schema.search_field do %>
  def search_<%= schema.plural %>(params) do
    search_term = Map.get(params, "search", "")
    page = Map.get(params, "page")

    database_query_params = %{
      filters: [%{
        field: :<%= schema.search_field %>,
        op: :like_and,
        value: [search_term]
      }],
      page_size: @<%= schema.singular %>_search_page_size,
      page: page
    }

    {:ok, {<%= schema.plural %>, meta}} =
      Flop.validate_and_run(<%= inspect schema.alias %>, database_query_params,
        for: <%= inspect schema.alias %>,
        repo: Repo
      )

      options =
        for <%= schema.singular %> <- <%= schema.plural %> do
          %{id: <%= schema.singular %>.id, text: <%= inspect schema.alias %>.as_text(<%= schema.singular %>)}
        end

    %{
      results: options,
      more: meta.has_next_page?
    }
  end<% else %>
  def search_<%= schema.plural %>(_params) do
    # Implement a custom way of searching <%= schema.plural %>
    raise UndefinedFunctionError, "<%= inspect(schema.alias) %> doesn't have a string field that can be used for search"
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
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.insert()
    |> Repo.preload_in_results(@<%= schema.singular %>_preloads)
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
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.update()
    |> Repo.preload_in_results(@<%= schema.singular %>_preloads)
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
  Returns an `%Ecto.Changeset{}` for tracking <%= schema.singular %> changes.

  ## Examples

      iex> change_<%= schema.singular %>(<%= schema.singular %>)
      %Ecto.Changeset{data: %<%= inspect schema.alias %>{}}

  """
  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    <%= schema.singular %>
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.preload(@<%= schema.singular %>_preloads)
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
  Checks for whether the user can browse <%= schema.plural %>.
  """
  @spec can_export_<%= schema.plural %>(maybe_user(), <%= inspect(schema.alias) %>.t()) :: authz_result()
  def can_export_<%= schema.plural %>(user, _<%= schema.singular %>) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end
