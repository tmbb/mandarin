defmodule <%= inspect context.web_module %>.MandarinComponents do
  use CodeGen,
    module: Bootstrap5Components,
    options: [
      gettext_module: <%= inspect context.web_module %>.Gettext
    ]
end
