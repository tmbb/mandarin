defmodule Bureaucrat.Router do
  @moduledoc """
  Macros to simplify the definition of routes.
  """
  require Phoenix.Router

  @doc """
  Add routes for a full-fledged Bureaucrat controller.

  The same as `Phoenix.Router.resources/3`, but with an extra `<resource>/select` route,
  for use with `Forage`'s select widget.
  """
  defmacro resources(prefix, module, _options \\ []) do
    select_path = "#{prefix}/select"

    quote do
      Phoenix.Router.get(unquote(select_path), unquote(module), :select)
      Phoenix.Router.resources(unquote(prefix), unquote(module))
    end
  end
end
