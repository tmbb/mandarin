defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>View do
  use <%= context.mandarin_web_module %>, :view<%
  # This code block is very weird, but it's the simplest way
  # of using `Enum.intersperse/2` to add a comma between the lines
  prefixes =
    for {_, k, string_alias, table_name_atom} <- schema.assocs do
      prefix = string_alias |> String.split(".") |> Enum.drop(-1) |> Enum.join(".")
      module_alias = Mandarin.Naming.table_name_to_module_name(table_name_atom)
      full_module = prefix <> "." <> module_alias
      "     #{context.basename}_#{k}: #{full_module}"
    end
%>

  use ForageWeb.ForageView,
    routes_module: Routes,
    error_helpers_module: <%= inspect context.web_module %>.ErrorHelpers,
    prefix: :<%= context.basename %>_<%= schema.singular %><%= if not(Enum.empty?(schema.assocs)) do %>,
    prefixes: [
<%= prefixes |> Enum.intersperse(",\n") |> Enum.join() %>
    ]<% end %>
end
