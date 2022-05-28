defmodule <%= install.web_module %>.<%= install.layout_view_module %> do
  use <%= install.mandarin_web_module %>, :view

  def show_live_dashboard?(_conn) do
    # IMPORTANT: this function is not a replacement for proper authorization
    # around access to the live dashboard!

    # Replace this constant by your custom logic
    user_should_see_live_dashboard? = true
    live_dashboard_route_exists? = function_exported?(Routes, :live_dashboard_path, 2)
    # Show the live dashboard if both conditions hold
    user_should_see_live_dashboard? and live_dashboard_route_exists?
  end
end
