defmodule <%= inspect context.web_module %>.<%= inspect context.alias %>.HomepageHTML do
  use <%= inspect context.web_module %>.MandarinWeb, :html

  embed_templates "homepage_html/*"
end
