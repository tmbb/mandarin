defmodule <%= inspect context.mandarin_web_module %> do
  @moduledoc """
  The entrypoint for defining the web interface to your Mandarin contexts,
  such as controllers, views, channels and so on.

  This module is analogous to the `YourAppWeb` module defined
  by the Phoenix generators.

  Mandarin, unlike Phoenix, implements a "vertical" folder structure
  which keeps controllers, views and templates together in the same file.

  This can be used in your application as:

      use <%= context.mandarin_web_module %>, :controller
      use <%= context.mandarin_web_module %>, :view

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
      import <%= inspect context.web_module %>.Gettext
      alias <%= inspect context.web_module %>.Router.Helpers, as: Routes
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
        layout: {<%= inspect context.web_module %>.LayoutView, "live.html"}

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
      import <%= inspect context.web_module %>.Gettext
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

      import <%= inspect context.web_module %>.ErrorHelpers
      import <%= inspect context.web_module %>.Gettext
      alias <%= inspect context.web_module %>.Router.Helpers, as: Routes
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

  # Helpers (kept here to keep the file self-contained
  # without runtime dependencies on Mandarin)
  defp namespace_from_module(module) do
    module
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end
end
