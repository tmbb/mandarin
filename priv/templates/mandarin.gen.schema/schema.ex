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

  schema <%= inspect schema.table %> do
<%= for {k, v} <- schema.types do %>    field <%= inspect k %>, <%= inspect v %><%= schema.defaults[k] %>
<% end %><%= for {_, k, string_alias, _} <- schema.assocs do %>    belongs_to :<%= k %>, <%= string_alias %>, on_replace: :nilify
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

  def select_search_field() do
    :<%= schema.attrs |> List.first() |> elem(0) %>
  end
end

defimpl ForageWeb.Display, for: <%= inspect schema.module %> do
  def display(<%= schema.singular %>) do
    "#{<%= schema.singular %>.<%= schema.attrs |> List.first() |> elem(0) %>}"
  end
end
