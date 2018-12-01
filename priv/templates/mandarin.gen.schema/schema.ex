defmodule <%= inspect schema.module %> do<%
  simple_fields = for {k, _} <- schema.attrs, do: k
  assoc_fields = for {_, k, _, _} <- schema.assocs, do: k
  all_fields = simple_fields ++ assoc_fields
  assoc_names = for {_, k, _, _} <- schema.assocs, do: String.replace_suffix(to_string(k), "_id", "")
%>
  use Ecto.Schema
  import Ecto.Changeset

<%= if schema.binary_id do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id<% end %>
  schema <%= inspect schema.table %> do
<%= for {k, v} <- schema.types do %>    field <%= inspect k %>, <%= inspect v %><%= schema.defaults[k] %>
<% end %><%= for {_, k, string_alias, _} <- schema.assocs do %><% assoc_name = String.replace_suffix(to_string(k), "_id", "") %>    belongs_to :<%= assoc_name %>, <%= string_alias %>, on_replace: :nilify
<% end %>
    timestamps()
  end

  @doc false
  def changeset(<%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> cast(attrs, [<%= Enum.map_join(all_fields, ", ", fn field -> inspect(field) end) %>])
    |> validate_required([<%= Enum.map_join(simple_fields, ", ", fn field -> inspect(field) end) %>])<%= for assoc_name <- assoc_names do %>
    |> cast_assoc(:<%= assoc_name %>)<% end %>
<%= for k <- schema.uniques do %>    |> unique_constraint(<%= inspect k %>)
<% end %>  end

  def display(nil), do: ""
  def display(<%= schema.singular %>), do: "#{<%= schema.singular %>.<%= schema.attrs |> List.first() |> elem(0) %>}"

  def select_search_field() do
    :<%= schema.attrs |> List.first() |> elem(0) %>
  end
end
