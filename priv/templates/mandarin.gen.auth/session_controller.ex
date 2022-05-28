defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>SessionController do
  use <%= inspect context.mandarin_web_module %>, :controller

  alias <%= inspect context.module %>
  alias <%= inspect auth_module %>

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"<%= schema.singular %>" => <%= schema.singular %>_params}) do
    %{"email" => email, "password" => password} = <%= schema.singular %>_params

    if <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>_by_email_and_password(email, password) do
      <%= inspect schema.alias %>Auth.log_in_<%= schema.singular %>(conn, <%= schema.singular %>, <%= schema.singular %>_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      error_message = dgettext("<%= schema.context_underscore %>", "Invalid email or password")

      render(conn, "new.html", error_message: error_message)
    end
  end

  def delete(conn, _params) do
    info_message = dgettext("<%= schema.context_underscore %>", "Logged out successfully.")

    conn
    |> put_flash(:info, info_message)
    |> <%= inspect schema.alias %>Auth.log_out_<%= schema.singular %>()
  end
end
