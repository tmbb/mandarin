defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>View do
  use <%= context.mandarin_web_module %>, :view
  <%= for {_, _,  string_alias, table_name_atom} <- schema.assocs do %><%
    prefix = string_alias |> String.split(".") |> Enum.drop(-1) |> Enum.join(".")
    module_alias = Mandarin.Naming.table_name_to_module_name(table_name_atom)
    full_module = prefix <> "." <> module_alias %>
  alias <%= full_module %><% end %>
  use ForageWeb.ForageView,
    routes_module: Routes,
    prefix: :<%= context.basename %>_<%= schema.singular %>
end
