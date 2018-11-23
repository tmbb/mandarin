defmodule Mix.Bureaucrat.Install do
  defstruct [
    :context_underscore,
    :context_camel_case,
    :web_module,
    :layout_view_underscore,
    :layout_view_camel_case,
    :web_path
  ]
end
