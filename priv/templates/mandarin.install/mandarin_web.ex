defmodule <%= install.mandarin_web_module %> do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use <%= install.mandarin_web_module %>, :controller
      use <%= install.mandarin_web_module %>, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller(opts) do
    ns = Keyword.fetch!(opts, :namespace)

    quote do
      use Phoenix.Controller,
        namespace: unquote(ns)

      import Plug.Conn
      import <%= install.web_module %>.Gettext
      alias <%= install.web_module %>.Router.Helpers, as: Routes
    end
  end

  def view(opts) do
    ns = Keyword.fetch!(opts, :namespace)

    quote do
      use Phoenix.View,
        root: "#{__DIR__}/templates",
        namespace: unquote(ns),
        path: ""

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers(opts))
    end
  end

  def live_view(opts) do
    quote do
      use Phoenix.LiveView,
        layout: {<%= install.web_module %>.LayoutView, "live.html"}

      unquote(view_helpers(opts))
    end
  end

  def live_component(opts) do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers(opts))
    end
  end

  def router(_opts) do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel(_opts) do
    quote do
      use Phoenix.Channel
      import <%= install.web_module %>.Gettext
    end
  end

  defp view_helpers(_opts) do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      import Phoenix.HTML.Tag

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import <%= install.web_module %>.ErrorHelpers
      import <%= install.web_module %>.Gettext
      alias <%= install.web_module %>.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which, opts \\ []) when is_atom(which) do
    default_ns = namespace_from_module(__CALLER__.module)
    ns = Keyword.get(opts, :namespace, default_ns)
    params = [namespace: ns]
    apply(__MODULE__, which, [params])
  end

  # Helpers
  defp namespace_from_module(module) do
    module
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end
end
