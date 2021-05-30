defmodule Mandarin.Router do
  @moduledoc """
  Macros to simplify the definition of routes.
  """
  require Phoenix.Router

  @doc """
  Add routes for a full-fledged Mandarin controller.

  The same as `Phoenix.Router.resources/3`, but with an extra `<resource>/select` route,
  for use with `Forage`'s select widget.
  """
  defmacro resources(prefix, module, opts \\ []) do
    select_path = "#{prefix}/select"
    except = opts |> Keyword.get(:except) |> wrap_if_not_nil()
    only = opts |> Keyword.get(:only) |> wrap_if_not_nil()

    select? =
      case {is_list(except), is_list(only)} do
        {true, true} ->
          raise "Can't have both :except and :only options..."

        {true, false} ->
          not (:select in except)

        {false, true} ->
          :select in only

        {false, false} ->
          true
      end

    only = remove_select(only)
    except = remove_select(except)

    opts_without_select =
      opts
      |> Keyword.put(:only, only)
      |> Keyword.put(:except, except)

    select_route =
      if select? do
        quote do
          Phoenix.Router.get(unquote(select_path), unquote(module), :select)
        end
      else
        nil
      end

    quote do
      unquote(select_route)
      Phoenix.Router.resources(unquote(prefix), unquote(module), unquote(opts_without_select))
    end
  end

  defp wrap_if_not_nil(nil), do: nil
  defp wrap_if_not_nil(other), do: List.wrap(other)

  defp remove_select(nil), do: nil
  defp remove_select(opts) when is_list(opts), do: List.delete(opts, :select)
end
