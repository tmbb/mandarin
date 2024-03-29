defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>ControllerTest do
  use <%= inspect context.web_module %>.ConnCase

  import <%= inspect context.module %>Fixtures

  @create_attrs <%= inspect schema.params.create %>
  @update_attrs <%= inspect schema.params.update %>
  @invalid_attrs <%= inspect for {key, _} <- schema.params.create, into: %{}, do: {key, nil} %>

  describe "index" do
    test "lists all <%= schema.pluralized %>", %{conn: conn} do
      conn = get conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :index)
      html = html_response(conn, 200)

      assert html =~ "Browse"
      assert html =~ "<%= schema.human_pluralized %>"
    end
  end

  describe "new <%= schema.singular %>" do
    test "renders form", %{conn: conn} do
      conn = get conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :new)
      html = html_response(conn, 200)

      assert html =~ "New"
      assert html =~ "<%= schema.human_singular %>"
    end
  end

  describe "create <%= schema.singular %>" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :create), <%= schema.singular %>: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, id)

      conn = get conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, id)
      html = html_response(conn, 200)

      assert html =~ "Show"
      assert html =~ "<%= schema.human_singular %>"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :create), <%= schema.singular %>: @invalid_attrs
      html = html_response(conn, 200)

      assert html =~ "New"
      assert html =~ "<%= schema.human_singular %>"
    end
  end

  describe "edit <%= schema.singular %>" do
    setup [:create_<%= schema.singular %>]

    test "renders form for editing chosen <%= schema.singular %>", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = get conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :edit, <%= schema.singular %>)
      html = html_response(conn, 200)

      assert html =~ "Edit"
      assert html =~ "<%= schema.human_singular %>"
    end
  end

  describe "update <%= schema.singular %>" do
    setup [:create_<%= schema.singular %>]

    test "redirects when data is valid", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = put conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :update, <%= schema.singular %>), <%= schema.singular %>: @update_attrs
      assert redirected_to(conn) == Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>)

      conn = get conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>)<%= if schema.string_attr do %>
      assert html_response(conn, 200) =~ <%= inspect Mix.Mandarin.Schema.default_param(schema, :update) %><% else %>
      assert html_response(conn, 200)<% end %>
    end

    test "renders errors when data is invalid", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = put conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :update, <%= schema.singular %>), <%= schema.singular %>: @invalid_attrs
      html = html_response(conn, 200)

      assert html =~ "Edit"
      assert html =~ "<%= schema.human_singular %>"
    end
  end

  describe "delete <%= schema.singular %>" do
    setup [:create_<%= schema.singular %>]

    test "deletes chosen <%= schema.singular %>", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = delete conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :delete, <%= schema.singular %>)
      assert redirected_to(conn) == Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, Routes.<%= context.basename %>_<%= schema.route_helper %>_path(conn, :show, <%= schema.singular %>)
      end
    end
  end

  defp create_<%= schema.singular %>(_) do
    <%= schema.singular %> = <%= schema.singular %>_fixture()
    %{<%= schema.singular %>: <%= schema.singular %>}
  end
end
