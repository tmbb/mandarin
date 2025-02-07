defimpl Bootstrap5Components.Resource, for: <%= inspect schema.module %> do
  use <%= inspect context.web_module %>.MandarinWeb, :verified_routes
  alias <%= inspect schema.module %>

  # Displays the <%= schema.singular %> as text (for `<select/>` options, for example)
  @spec as_text(<%= inspect schema.alias %>.t()) :: String.t()<%= if schema.search_field do %>
  def as_text(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    <%= schema.singular %>.<%= schema.search_field %>
  end<% else %>
  def as_text(%<%= inspect schema.alias %>{} = _<%= schema.singular %>) do
    # Define a custom string representation for this schema
    raise UndefinedFunctionError, "<%= inspect(schema.alias) %> doesn't have a string field that can be used for display"
  end
<% end %>

  # Displays the <%= schema.singular %> as text (for `<select/>` options, for example)
  @spec as_html(<%= inspect schema.alias %>.t()) :: String.t()<%= if schema.search_field do %>
  def as_html(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    <%= schema.singular %>.<%= schema.search_field %>
  end<% else %>
  def as_html(%<%= inspect schema.alias %>{} = _<%= schema.singular %>) do
    # Define a custom string representation for this schema
    raise UndefinedFunctionError, "<%= inspect(schema.alias) %> doesn't have a string field that can be used for display"
  end
<% end %>

  @spec path_for(<%= inspect schema.alias %>.t()) :: String.t()
  def path_for(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>.id}"
  end
end
