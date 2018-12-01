defmodule Mandarin do
  @moduledoc """
  A package containing generators to generate an admin backend for your Phoenix app.

  The package relies a lot on generators, and Mandarin itself provides a minimal API at runtime.
  This is be design, as the code produced with generators is easier to customize than overridable
  API calls, or other alternatives that depend a lot on macros.

  The basic idea is tha Mandarin generates normal Phoenix contexts, views, templates and controllers,
  much like the ones you'd write yourself.
  The generated files follow roughly the same conventinos as the ones you'd write yourself.

  Mandarin relies heavily on the [forage](https://github.com/tmbb/forage) package
  for filtering, sorting and paginating the results in the CRUD views.
  """
end
