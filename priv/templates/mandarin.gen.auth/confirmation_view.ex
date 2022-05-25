defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>ConfirmationView do
  use <%= inspect context.mandarin_web_module %>, :view

  use ForageWeb.ForageView,
    routes_module: Routes,
    error_helpers_module: <%= inspect context.web_module %>.ErrorHelpers,
    prefix: :<%= schema.route_helper%>_confirmation
end
