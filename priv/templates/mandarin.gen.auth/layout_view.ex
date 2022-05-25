defmodule <%= inspect context.web_module %>.<%= context.name %>.LayoutView do
  use <%= inspect context.mandarin_web_module %>, :view

  use ForageWeb.ForageView,
    routes_module: Routes,
    error_helpers_module: <%= inspect context.web_module %>.ErrorHelpers,
    prefix: nil
end
