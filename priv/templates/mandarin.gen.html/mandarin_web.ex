defmodule <%= inspect context.web_module %>.MandarinWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use <%= inspect context.web_module %>, :controller
      use <%= inspect context.web_module %>, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router(_opts) do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel(_opts) do
    quote do
      use Phoenix.Channel
    end
  end

  def controller(opts) do
    caller = Keyword.fetch!(opts, :caller)
    default_layouts = default_layouts_module(caller.module)
    layouts = Keyword.get(opts, :layouts, default_layouts)

    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: unquote(layouts)]

      import Plug.Conn
      import <%= inspect context.web_module %>.Gettext

      unquote(verified_routes())
    end
  end

  def live_view(opts) do
    caller = Keyword.fetch!(opts, :caller)
    default_layouts = default_layouts_module(caller.module)
    layouts = Keyword.get(opts, :layouts, default_layouts)

    quote do
      use Phoenix.LiveView,
        layout: {unquote(layouts), :app}

      unquote(html_helpers())
    end
  end

  def live_component() do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html(_opts) do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers() do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import <%= inspect context.web_module %>.MandarinComponents
      import <%= inspect context.web_module %>.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes(_opts \\ []) do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: <%= inspect context.web_module %>.Endpoint,
        router: <%= inspect context.web_module %>.Router,
        statics: <%= inspect context.web_module %>.static_paths()
    end
  end

  defp default_layouts_module(module) do
    module
    |> Module.split()
    |> Enum.drop(-1)
    |> Kernel.++(["Layouts"])
    |> Module.concat()
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    opts = [caller: __CALLER__]
    apply(__MODULE__, which, [opts])
  end
end
