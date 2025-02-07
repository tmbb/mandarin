defmodule <%= inspect context.web_module %>.<%= inspect context.alias %>.Layouts do
  use <%= inspect context.web_module %>.MandarinWeb, :html

  embed_templates "layouts/*"
end
