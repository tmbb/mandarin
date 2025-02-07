defmodule <%= inspect schema.module %> do
  use Ecto.Schema
  import Ecto.Changeset
<%= Mix.Mandarin.Schema.assoc_aliases(schema) %>
  @type t :: %__MODULE__{}
<% foreign_ids = for {_, k, _, _} <- schema.assocs, do: k %>
  @derive {
    Flop.Schema,
    filterable: <%= Mix.Mandarin.multiline_list(
      Keyword.keys(schema.attrs),
      element_indent_level: 6,
      bracket_indent_level: 4
    ) %>,
    sortable: <%= Mix.Mandarin.multiline_list(
      Keyword.keys(schema.attrs),
      element_indent_level: 6,
      bracket_indent_level: 4
    ) %>
  }
<%= if schema.prefix do %>
  @schema_prefix :<%= schema.prefix %><% end %><%= if schema.binary_id do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
<% end %>
  schema <%= inspect schema.table %> do
<%= Mix.Mandarin.Schema.format_fields_for_schema(schema) %>

    timestamps(<%= if schema.timestamp_type != :naive_datetime, do: "type: #{inspect schema.timestamp_type}" %>)
  end

  @doc false
  def changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [<%= Mix.Mandarin.Schema.attrs_to_cast(schema) %>])
    |> validate_required([<%= Enum.map_join(Mix.Mandarin.Schema.required_fields(schema), ", ", &inspect(elem(&1, 0))) %>])
<%= for k <- schema.uniques do %>    |> unique_constraint(<%= inspect k %>)
<% end %><%= for {_, k, _, _} <- schema.assocs do %>    |> cast_assoc(:<%= k |> to_string() |> String.trim_trailing("_id") %>)
<% end %>  end
end
