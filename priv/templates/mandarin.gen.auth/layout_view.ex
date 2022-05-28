defmodule <%= inspect context.web_module %>.<%= context.name %>.LayoutView do
  use <%= inspect context.mandarin_web_module %>, :view

  def show_live_dashboard?(_conn) do
    # IMPORTANT: this function is not a replacement for proper authorization
    # around access to the live dashboard!

    # Replace this constant by your custom logic
    user_should_see_live_dashboard? = true
    live_dashboard_route_exists? = function_exported?(Routes, :live_dashboard_path, 2)
    # Show the live dashboard if both conditions hold
    user_should_see_live_dashboard? and live_dashboard_route_exists?
  end

  use ForageWeb.ForageView,
    routes_module: Routes,
    error_helpers_module: <%= inspect context.web_module %>.ErrorHelpers,
    prefix: nil
end
