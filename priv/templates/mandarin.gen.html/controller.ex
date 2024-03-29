defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Controller do
  use <%= inspect context.mandarin_web_module %>, :controller

  alias <%= inspect context.module %>
  alias <%= inspect schema.module %>
  alias ForageWeb.ForageController

  def index(conn, params) do
    <%= schema.pluralized %> = <%= inspect context.alias %>.list_<%= schema.pluralized %>(params)
    render(conn, "index.html", <%= schema.pluralized %>: <%= schema.pluralized %>)
  end

  def new(conn, _params) do
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(%<%= inspect schema.alias %>{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    case <%= inspect context.alias %>.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        conn
        |> put_flash(:info, dgettext("<%= context.basename %>", "<%= schema.human_singular %> created successfully."))
        |> redirect(to: Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    render(conn, "show.html", <%= schema.singular %>: <%= schema.singular %>)
  end

  def edit(conn, %{"id" => id}) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)
    render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
  end

  def update(conn, %{"id" => id, <%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)

    case <%= inspect context.alias %>.update_<%= schema.singular %>(<%= schema.singular %>, <%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        conn
        |> put_flash(:info, dgettext("<%= context.basename %>", "<%= schema.human_singular %> updated successfully."))
        |> redirect(to: Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    {:ok, _<%= schema.singular %>} = <%= inspect context.alias %>.delete_<%= schema.singular %>(<%= schema.singular %>)
    # After deleting, remain on the same page
    redirect_params = ForageController.pagination_from_params(params)

    conn
    |> put_flash(:info, dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted successfully."))
    |> redirect(to: Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :index, redirect_params))
  end
<% display_field = Mix.Mandarin.Schema.default_search_field(schema) %><%= if display_field do %>
  def select(conn, %{"_search" => _search_term} = params) do
    # Page of database records matching the search term
    <%= schema.pluralized %> = <%= inspect context.alias %>.search_<%= schema.pluralized %>(params)
    # Extract only the data we care about
    # For greater efficiency, you can write a custom search query
    data = ForageController.forage_select_data(<%= schema.pluralized %>, :<%= display_field %>)
    json(conn, data)
  end<% else %>
  def select(conn, %{"_search" => _search_term} = params) do
    # Page of database records matching the search term
    <%= schema.pluralized %> = <%= inspect context.alias %>.search_<%= schema.pluralized %>(params)
    # Extract only the data we care about
    # For greater efficiency, you can write a custom search query
    data = ForageController.forage_select_data(<%= schema.pluralized %>)
    json(conn, data)
  end
<% end %>
end
