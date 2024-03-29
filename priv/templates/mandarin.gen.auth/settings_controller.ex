defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>SettingsController do
  use <%= inspect context.mandarin_web_module %>, :controller

  alias <%= inspect context.module %>
  alias <%= inspect auth_module %>

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"<%= schema.singular %>" => <%= schema.singular %>_params} = params
    %{"current_password" => password} = <%= schema.singular %>_params

    <%= schema.singular %> = conn.assigns.current_<%= schema.singular %>

    case <%= inspect context.alias %>.apply_<%= schema.singular %>_email(<%= schema.singular %>, password, <%= schema.singular %>_params) do
      {:ok, applied_<%= schema.singular %>} ->
        <%= inspect context.alias %>.deliver_<%= schema.singular %>_update_email_instructions(
          applied_<%= schema.singular %>,
          <%= schema.singular %>.email,
          &Routes.<%= schema.route_helper %>_settings_url(conn, :confirm_email, &1)
        )

        info_message = dgettext("<%= schema.context_underscore %>", "A link to confirm your email change has been sent to the new address.")

        conn
        |> put_flash(:info, info_message)
        |> redirect(to: Routes.<%= schema.route_helper %>_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"<%= schema.singular %>" => <%= schema.singular %>_params} = params
    %{"current_password" => password} = <%= schema.singular %>_params

    <%= schema.singular %> = conn.assigns.current_<%= schema.singular %>

    case <%= inspect context.alias %>.update_<%= schema.singular %>_password(<%= schema.singular %>, password, <%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        info_message = dgettext("<%= schema.context_underscore %>", "Password updated successfully.")

        conn
        |> put_flash(:info, info_message)
        |> put_session(:<%= schema.singular %>_return_to, Routes.<%= schema.route_helper %>_settings_path(conn, :edit))
        |> <%= inspect schema.alias %>Auth.log_in_<%= schema.singular %>(<%= schema.singular %>)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case <%= inspect context.alias %>.update_<%= schema.singular %>_email(conn.assigns.current_<%= schema.singular %>, token) do
      :ok ->
        info_message = dgettext("<%= schema.context_underscore %>", "Email changed successfully.")

        conn
        |> put_flash(:info, info_message)
        |> redirect(to: Routes.<%= schema.route_helper %>_settings_path(conn, :edit))

      :error ->
        info_message = dgettext("<%= schema.context_underscore %>", "Email change link is invalid or it has expired.")

        conn
        |> put_flash(:error, info_message)
        |> redirect(to: Routes.<%= schema.route_helper %>_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    <%= schema.singular %> = conn.assigns.current_<%= schema.singular %>

    conn
    |> assign(:email_changeset, <%= inspect context.alias %>.change_<%= schema.singular %>_email(<%= schema.singular %>))
    |> assign(:password_changeset, <%= inspect context.alias %>.change_<%= schema.singular %>_password(<%= schema.singular %>))
  end
end
