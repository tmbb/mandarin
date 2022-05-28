defmodule <%= inspect schema.module %> do<%
  simple_fields = for {k, _} <- schema.attrs, do: k
  assoc_fields = for {_, k, _, _} <- schema.assocs, do: k
  foreign_keys = for k <- assoc_fields, do: :"#{k}_id"
  simple_fields_and_foreign_keys = simple_fields ++ foreign_keys
  all_fields = simple_fields ++ assoc_fields
%>
  use Ecto.Schema
  import Ecto.Changeset
<%= if schema.binary_id do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id<% end %>

  @derive Phoenix.Param

  schema <%= inspect schema.table %> do
<%= for {k, _v} <- schema.attrs do %>    field <%= inspect k %>, <%= inspect schema.types[k] %><%= schema.defaults[k] %>
<% end %><%= for {_, k, string_alias, table_name_atom} <- schema.assocs do %><%
  prefix = string_alias |> String.split(".") |> Enum.drop(-1) |> Enum.join(".")
  module_alias = Mandarin.Naming.table_name_to_module_name(table_name_atom)
  full_module = prefix <> "." <> module_alias
%>    belongs_to :<%= k %>, <%= full_module %>, on_replace: :nilify
<% end %>
    timestamps()
  end

  @doc false
  def changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [<%= Enum.map_join(simple_fields_and_foreign_keys, ", ", fn field -> inspect(field) end) %>])
    |> validate_required([<%= Enum.map_join(simple_fields, ", ", fn field -> inspect(field) end) %>])<%= for k <- assoc_fields do %>
    |> cast_assoc(:<%= k %>)<% end %>
<%= for k <- schema.uniques do %>    |> unique_constraint(<%= inspect k %>)
<% end %>  end
end

<% display_field = Mix.Mandarin.Schema.default_search_field(schema) %><%= if display_field do %>
defimpl ForageWeb.Display, for: <%= inspect schema.module %> do
  def as_text(<%= schema.singular %>) do
    to_string(<%= schema.singular %>.<%= display_field %>)
  end

  def as_html(<%= schema.singular %>) do
    as_text(<%= schema.singular %>)
  end
end<% end %>
