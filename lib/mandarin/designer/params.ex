defmodule Mandarin.Designer.Params do
  @moduledoc false

  defstruct alias: nil,
            context: nil,
            table: nil,
            binary_id: true,
            generate_migration?: true,
            is_join_through?: false,
            yes?: true,
            fields: []

  def new(opts) do
    struct(__MODULE__, opts)
  end

  def join_through_relation(opts) do
    new_opts = Keyword.put(opts, :is_join_through?, true)
    new(new_opts)
  end
end
