defmodule Bureaucrat.Plugs.Resource do
  import Plug.Conn

  def init(default), do: default

  def call(conn, default) do
    assign(conn, :bureaucrat_resource, default)
  end
end
