defmodule Mix.Mandarin.Install do
  @moduledoc false
  defstruct [
    :app,
    :context_underscore,
    :context_camel_case,
    :context_app,
    :web_module,
    :mandarin_web_module,
    :layout_view_underscore,
    :layout_view_camel_case,
    :web_path
  ]

  def new(opts) do
    struct(__MODULE__, opts)
  end
end
