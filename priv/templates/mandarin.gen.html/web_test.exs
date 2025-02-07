defmodule <%= inspect Module.concat([context.web_module, schema.web_namespace, schema.alias]) %>Test do
  use <%= inspect context.web_module %>.ConnCase

  import <%= inspect context.module %>Fixtures

  @create_attrs <%= Mix.Mandarin.to_text schema.params.create %>
  @update_attrs <%= Mix.Mandarin.to_text schema.params.update %>
  @invalid_attrs <%= Mix.Mandarin.to_text (for {key, _} <- schema.params.create, into: %{}, do: {key, nil}) %>

  describe "index" do
    test "lists all <%= schema.plural %>", %{conn: conn} do
      conn = get(conn, ~p"<%= schema.route_prefix %>")
      assert html_response(conn, 200) =~ "Listing <%= schema.human_plural %>"
    end
  end

  describe "new <%= schema.singular %>" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"<%= schema.route_prefix %>/new")
      assert html_response(conn, 200) =~ "New <%= schema.human_singular %>"
    end
  end

  describe "create <%= schema.singular %>" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"<%= schema.route_prefix %>", <%= schema.singular %>: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"<%= schema.route_prefix %>/#{id}"

      conn = get(conn, ~p"<%= schema.route_prefix %>/#{id}")
      assert html_response(conn, 200) =~ "<%= schema.human_singular %> #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"<%= schema.route_prefix %>", <%= schema.singular %>: @invalid_attrs)
      assert html_response(conn, 200) =~ "New <%= schema.human_singular %>"
    end
  end

  describe "edit <%= schema.singular %>" do
    setup [:create_<%= schema.singular %>]

    test "renders form for editing chosen <%= schema.singular %>", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = get(conn, ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}/edit")
      assert html_response(conn, 200) =~ "Edit <%= schema.human_singular %>"
    end
  end

  describe "update <%= schema.singular %>" do
    setup [:create_<%= schema.singular %>]

    test "redirects when data is valid", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = put(conn, ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}", <%= schema.singular %>: @update_attrs)
      assert redirected_to(conn) == ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}"

      conn = get(conn, ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}")<%= if schema.string_attr do %>
      assert html_response(conn, 200) =~ <%= inspect Mix.Mandarin.Schema.default_param(schema, :update) %><% else %>
      assert html_response(conn, 200)<% end %>
    end

    test "renders errors when data is invalid", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = put(conn, ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}", <%= schema.singular %>: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit <%= schema.human_singular %>"
    end
  end

  describe "delete <%= schema.singular %>" do
    setup [:create_<%= schema.singular %>]

    test "deletes chosen <%= schema.singular %>", %{conn: conn, <%= schema.singular %>: <%= schema.singular %>} do
      conn = delete(conn, ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}")
      assert redirected_to(conn) == ~p"<%= schema.route_prefix %>"

      assert_error_sent 404, fn ->
        get(conn, ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>}")
      end
    end
  end

  defp create_<%= schema.singular %>(_) do
    <%= schema.singular %> = <%= schema.singular %>_fixture()
    %{<%= schema.singular %>: <%= schema.singular %>}
  end
end
