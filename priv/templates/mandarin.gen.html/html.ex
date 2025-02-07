defmodule <%= inspect Module.concat([context.web_module, schema.web_namespace, schema.alias]) %>HTML do
  use <%= inspect context.web_module %>.MandarinWeb, :html

  embed_templates "<%= schema.singular %>_html/*"
end
