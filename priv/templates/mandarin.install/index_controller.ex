defmodule <%= install.web_module %>.<%= install.context_camel_case %>.IndexController do
  use <%= install.mandarin_web_module %>, :controller

  def index(conn, _params) do
    render(conn, "index.html", context: "<%= install.context_camel_case %>")
  end
end
