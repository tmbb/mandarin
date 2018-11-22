defmodule Bureaucrat.Router do
  require Phoenix.Router

  defmacro resources(prefix, module, _options \\ []) do
    select_path = "#{prefix}/select"

    quote do
      Phoenix.Router.get(unquote(select_path), unquote(module), :select)
      Phoenix.Router.resources(unquote(prefix), unquote(module))
    end
  end
end
