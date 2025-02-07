defmodule <%= inspect context.module %> do
  @moduledoc """
  The <%= context.name %> context.
  """

  import Ecto.Query, warn: false
  alias <%= inspect schema.repo %>

  # Note: replace by your actual user type. This can't be inferred by the generators.
  @type user() :: any()
  @type maybe_user() :: user() | nil

  # The error names follow the HTTP conventions.
  #
  #   - :unauthorized - the user doesn't have valid credentials
  #   - :forbidden - the user has valid credentials but can't access the resource
  #
  # This naming is confusing because it mixes authorization with authentication,
  # but in order to avoid surprises it's best to keep to HTTP semantics where
  # it makes sense
  @type authz_result() :: :ok | {:error, :unauthorized} | {:error, :forbidden}

  @spec can_access_<%= context.basename %>(maybe_user()) :: authz_result()
  def can_access_<%= context.basename %>(user) do
    case user do
      nil -> {:error, :unauthorized}
      _user -> :ok
    end
  end
end
