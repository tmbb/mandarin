defmodule <%= inspect Module.concat([context.web_module, schema.web_namespace, schema.alias]) %>Controller do
  use <%= inspect context.web_module %>.MandarinWeb, :controller

  alias <%= inspect context.module %>

  # Normal controller actions
  # =========================

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(id)

    case <%= inspect context.alias %>.can_read_<%= schema.singular %>(current_user, <%= schema.singular %>) do
      :ok ->
        render(conn, :show, <%= schema.singular %>: <%= schema.singular %>)

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't access <%= schema.human_singular %>.")
        handle_authorization_error(conn, message, error)
    end
  end

  # Error rendering
  # ===============
  # You can override these if you want something custom.
  # This should be good enough for a starting point.

  @spec handle_authorization_error(Plug.Conn.t(), String.t(), {:error, atom()}) :: Plug.Conn.t()
  def handle_authorization_error(conn, message, {:error, _reason} = error) do
    {status, access_message} =
      case error do
        # This is called when the current_user isn't properly authenticated.
        # This is equivalent to a 401 HTTP status.
        {:error, :unauthorized} ->
          {401, dgettext("<%= context.basename %>", "HTTP 401 - Unauthorized access. Please login.")}

        # This clause is called when the current_user is properly authenticated
        # but can't access the resource. This is equivalent to a 403 HTTP status.
        {:error, :forbidden} ->
          {403, dgettext("<%= context.basename %>", "HTTP 403 - Access forbidden.")}
      end

    full_message = access_message <> " " <> message

    conn
    |> put_flash(:error, full_message)
    |> put_status(status)
    |> redirect(to: ~p"/")
  end
end
