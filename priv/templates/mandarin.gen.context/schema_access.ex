<% preload = for {key, _, _, _} <- schema.assocs, do: key %>
  alias <%= inspect schema.module %>

  @doc """
  Returns a filtered list of <%= schema.plural %>.

  The list is filtered by `params["_filter"]`, sorted by `params["_sort"]
  and paginated according to `params["_pagination"].

  ## Examples

      iex> list_<%= schema.plural %>(params)
      [%<%= inspect schema.alias %>{}, ...]

  """
  def list_<%= schema.plural %>(params) do<%
      maybe_default_sort_field = Mix.Mandarin.Schema.maybe_default_sort_field(schema)
      sort_fields = maybe_default_sort_field ++ [:id]
    %>
    Forage.paginate(params, <%= inspect schema.alias %>, Repo, sort: <%= inspect(sort_fields) %>, preload: <%= inspect(preload) %>)
  end

  @doc """
  Runs a search query on <%= schema.plural %>.

  ## Examples

      iex> search_<%= schema.plural %>(params)
      [%<%= inspect schema.alias %>{}, ...]

  """<% search_field = Mix.Mandarin.Schema.default_search_field(schema) %><%= if search_field do %>
  def search_<%= schema.plural %>(params) do
    search_params = Forage.naive_search_params(params, :<%= search_field %>)
    list_<%= schema.plural %>(search_params)
  end<% else %>
  def search_<%= schema.plural %>(_params) do
    raise UndefinedFunctionError, "<%= inspect(schema.alias) %> doesn't have a string field that can be used for for search"
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
  def get_<%= schema.singular %>!(id), do: Repo.get!(<%= inspect schema.alias %>, id) |> Repo.preload(<%= inspect(preload) %>)

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
  end

  @doc """
  Deletes a <%= inspect schema.alias %>.

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
      %Ecto.Changeset{source: %<%= inspect schema.alias %>{}}

  """
  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, %{})
  end
