defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Controller do
  use <%= inspect context.web_module %>, :controller

  alias <%= inspect context.module %>
  alias <%= inspect schema.module %>
  alias ForageWeb.ForageController

  # Adds the the resource type to the conn
  plug Bureaucrat.Plugs.Resource, :<%= schema.singular %>

  def index(conn, params) do
    <%= schema.plural %> = <%= inspect context.alias %>.list_<%= schema.plural %>(params)
    render(conn, "index.html", <%= schema.plural %>: <%= schema.plural %>)
  end

  def new(conn, _params) do
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(%<%= inspect schema.alias %>{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    case <%= inspect context.alias %>.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        conn
        |> put_flash(:info, "<%= schema.human_singular %> created successfully.")
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
        |> put_flash(:info, "<%= schema.human_singular %> updated successfully.")
        |> redirect(to: Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)
    {:ok, _<%= schema.singular %>} = <%= inspect context.alias %>.delete_<%= schema.singular %>(<%= schema.singular %>)
    # After deleting, remain on the same page
    redirect_params = Map.take(params, ["_pagination"])

    conn
    |> put_flash(:info, "<%= schema.human_singular %> deleted successfully.")
    |> redirect(to: Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :index, redirect_params))
  end

  def select(conn, params) do
    <%= schema.plural %> = <%= inspect context.alias %>.list_<%= schema.plural %>(params)
    data = ForageController.forage_select_data(<%= schema.plural %>, &<%= inspect(schema.alias) %>.display/1)
    json(conn, data)
  end
end
