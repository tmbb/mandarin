defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>SettingsControllerTest do
  use <%= inspect context.web_module %>.ConnCase<%= test_case_options %>

  alias <%= inspect context.module %>
  import <%= inspect context.module %>Fixtures

  setup :register_and_log_in_<%= schema.singular %>

  describe "GET <%= web_path_prefix %>/<%= schema.plural %>/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if <%= schema.singular %> is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.<%= schema.route_helper %>_session_path(conn, :new)
    end
  end

  describe "PUT <%= web_path_prefix %>/<%= schema.plural %>/settings (change password form)" do
    test "updates the <%= schema.singular %> password and resets tokens", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      new_password_conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update), %{
          "action" => "update_password",
          "<%= schema.singular %>" => %{
            "current_password" => valid_<%= schema.singular %>_password(),
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.<%= schema.route_helper %>_settings_path(conn, :edit)
      assert get_session(new_password_conn, :<%= schema.singular %>_token) != get_session(conn, :<%= schema.singular %>_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email_and_password(<%= schema.singular %>.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update), %{
          "action" => "update_password",
          "<%= schema.singular %>" => %{
            "current_password" => "invalid",
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :<%= schema.singular %>_token) == get_session(conn, :<%= schema.singular %>_token)
    end
  end

  describe "PUT <%= web_path_prefix %>/<%= schema.plural %>/settings (change email form)" do
    @tag :capture_log
    test "updates the <%= schema.singular %> email", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update), %{
          "action" => "update_email",
          "<%= schema.singular %>" => %{
            "email" => unique_<%= schema.singular %>_email(),
            "current_password" => valid_<%= schema.singular %>_password(),
          }
        })

      assert redirected_to(conn) == Routes.<%= schema.route_helper %>_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(<%= schema.singular %>.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :update), %{
          "action" => "update_email",
          "<%= schema.singular %>" => %{
            "email" => "with spaces",
            "current_password" => "invalid"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET <%= web_path_prefix %>/<%= schema.plural %>/settings/confirm_email/:token" do
    setup %{<%= schema.singular %>: <%= schema.singular %>} do
      email = unique_<%= schema.singular %>_email()

      token =
        extract_<%= schema.singular %>_token(fn url ->
          <%= inspect context.alias %>.deliver_<%= schema.singular %>_update_email_instructions(%{<%= schema.singular %> | email: email}, <%= schema.singular %>.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the <%= schema.singular %> email once", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>, token: token, email: email} do
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.<%= schema.route_helper %>_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(<%= schema.singular %>.email)
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(email)

      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.<%= schema.route_helper %>_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.<%= schema.route_helper %>_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert <%= inspect context.alias %>.get_<%= schema.singular %>_by_email(<%= schema.singular %>.email)
    end

    test "redirects if <%= schema.singular %> is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.<%= schema.route_helper %>_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.<%= schema.route_helper %>_session_path(conn, :new)
    end
  end
end
