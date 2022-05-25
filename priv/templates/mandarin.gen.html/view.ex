defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>View do
  use <%= inspect context.mandarin_web_module %>, :view<%
  # This code block is very weird, but it's the simplest way
  # of using `Enum.intersperse/2` to add a comma between the lines
  prefixes =
    for {_, k, string_alias, _table_name_atom} <- schema.assocs do
      "     #{context.basename}_#{k}: #{string_alias}"
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
