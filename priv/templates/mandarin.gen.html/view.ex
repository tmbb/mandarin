defmodule <%= inspect context.web_module %>.<%= context.name %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>View do
  use <%= inspect context.web_module %>, :view<%= for {_, _, full_module_name, _} <- schema.assocs do %>
  alias <%= full_module_name %>
  <% end %>
  use ForageWeb.ForageView,
    routes_module: Routes,
    prefix: :<%= context.basename %>_<%= schema.singular %>
end
