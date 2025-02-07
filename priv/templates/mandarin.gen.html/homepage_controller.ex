defmodule <%= inspect context.web_module %>.<%= inspect context.alias %>.HomepageController do
  use <%= inspect context.web_module %>.MandarinWeb, :controller

  alias <%= inspect context.module %>

  # Normal controller actions
  # =========================

  def homepage(conn, _params) do
    user = conn.assigns[:current_user]

    case <%= inspect context.alias %>.can_access_<%= context.basename %>(user) do
      :ok ->
        render(conn, "homepage.html")

      {:error, _reason} = error ->
        handle_authorization_error(conn, error)
    end
  end

  # Error rendering
  # ==============================================================
  # You can override these if you want something custom.
  # This should be good enough for a starting point.

  @spec handle_authorization_error(Plug.Conn.t(), {:error, atom()}) :: Plug.Conn.t()
  def handle_authorization_error(conn, {:error, _reason} = error) do
    {status, message} =
      case error do
        # This is called when the user isn't properly authenticated.
        # This is equivalent to a 401 HTTP status.
        {:error, :unauthorized} ->
          {401, dgettext("<%= context.basename %>", "HTTP 401 - Unauthorized access. Please login.")}

        # This clause is called when the user is properly authenticated
        # but can't access the resource. This is equivalent to a 403 HTTP status.
        {:error, :forbidden} ->
          {403, dgettext("<%= context.basename %>", "HTTP 403 - Access forbidden.")}
      end

    conn
    |> put_flash(:error, message)
    |> put_status(status)
    |> redirect(to: ~p"/")
  end
end
