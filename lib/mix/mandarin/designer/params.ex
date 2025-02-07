defmodule Mandarin.Designer.Params do
  @moduledoc """
  Parameters to help design Mandarin contexts.
  """

  alias Mandarin.Designer.Params

  @type t :: %__MODULE__{}

  defstruct alias: nil,
            context: nil,
            table: nil,
            binary_id: true,
            generate_migration?: true,
            is_join_through?: false,
            yes?: true,
            fields: []

  @doc false
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @doc false
  def join_through_relation(opts) do
    new_opts = Keyword.put(opts, :is_join_through?, true)
    new(new_opts)
  end


  @doc """
  Update the parameter options for a list of parameters
  """
  @spec update_options(list(Params.t()), Keyword.t()) :: list(Params.t())
  def update_options(list_of_params, options) do
    options_map = Map.new(options)

    for params <- list_of_params do
      Map.merge(params, options_map)
    end
  end
end
