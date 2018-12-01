defmodule Mandarin.Plugs.Resource do
  @moduledoc """
  A trivial plug to add the type of resource to the `conn`.

  Currently this is used by the generators to decide which link in the sidebar has focus.
  """
  import Plug.Conn

  @doc false
  def init(default), do: default

  @doc false
  def call(conn, default) do
    assign(conn, :mandarin_resource, default)
  end
end
