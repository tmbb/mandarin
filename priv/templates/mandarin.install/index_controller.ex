defmodule <%= install.web_module %>.<%= install.context_camel_case %>.IndexController do
  use <%= install.web_module %>, :controller

  def index(conn, params) do
    render(conn, "index.html", context: "<%= install.context_camel_case %>")
  end
end
