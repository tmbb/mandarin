defmodule <%= inspect Module.concat([context.web_module, schema.web_namespace, schema.alias]) %>LiveEdit do
  use <%= inspect context.web_module %>.MandarinWeb, :live_view
  alias <%= inspect context.base_module %>.MandarinNotifications

  import <%= inspect context.web_module %>.<%= inspect context.alias %>.<%= inspect schema.alias %>HTML
  alias <%= inspect context.module %>
  alias <%= inspect schema.module %>

  def mount(%{"id" => <%= schema.singular %>_id}, _session, socket) do
    # We already have an ID - we are editing an existing <%= schema.human_singular %>
    current_user = socket.assigns[:current_user]
    # Get the <%= schema.human_singular %> by ID
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>_id)

    case <%= inspect context.alias %>.can_edit_<%= schema.singular %>(current_user, <%= schema.singular %>) do
      :ok ->
        # Subscribe to the <%= schema.human_singular %> resource we're editing.
        # Subscribe to the main channel to be notified if the resource is deleted.
        MandarinNotifications.subscribe("<%= schema.singular %>")
        MandarinNotifications.subscribe("<%= schema.singular %>:#{<%= schema.singular %>_id}")

        changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)
        path = "<%= schema.route_prefix %>/#{<%= schema.singular %>_id}/edit"
        socket = initialize_socket(socket, changeset, <%= schema.singular %>_id, path)
        {:ok, socket, temporary_assigns: [form: nil]}

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't edit <%= schema.human_singular %>.")
        {:error, handle_authorization_error(socket, message, error)}
    end
  end

  def mount(%{} = _params, _session, socket) do
    # We don't have an ID - we are creating a new <%= schema.human_singular %>
    current_user = socket.assigns[:current_user]

    case <%= inspect context.alias %>.can_create_<%= schema.singular %>(current_user) do
      :ok ->
        <%= schema.singular %> = <%= inspect context.alias %>.new_<%= schema.singular %>()
        changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)
        path = "<%= schema.route_prefix %>/new"
        socket = initialize_socket(socket, changeset, nil, path)
        {:ok, socket, temporary_assigns: [form: nil]}

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't create <%= schema.human_singular %>.")
        {:error, handle_authorization_error(socket, message, error)}
    end
  end

  defp initialize_socket(socket, changeset, <%= schema.singular %>_id, path) do
    form =
      changeset
      |> Map.put(:action, :update)
      |> to_form()

    assign(socket,
      <%= schema.singular %>_id: <%= schema.singular %>_id,
      action: path,<%= for {key, _, _, _} <- schema.assocs do %><% key_plural = Inflex.pluralize(key) %>
      <%= key %>_options: <%= inspect context.alias %>.list_<%= key_plural %>_as_options(),<% end %>
      form: form
    )
  end

  def render(assigns) do
    <%= schema.singular %>_live_form(assigns)
  end

  # Handle notifications from other clients editing the <%= schema.human_singular %>.
  # These handlers are not activated if the client has been edited by the same process.

  def handle_info({:resource_created, _id, _meta}, socket) do
    {:noreply, socket}
  end

  def handle_info({:draft_updated, <%= schema.singular %>_params, _meta}, socket) do
    update_draft_<%= schema.singular %>(<%= schema.singular %>_params, socket)
  end

  def handle_info({:resource_updated, %{"id" => <%= schema.singular %>_id} = _<%= schema.singular %>_params, _meta}, socket) do
    socket =
      socket
      |> put_flash(:info, dgettext("<%= context.basename %>", "<%= schema.human_singular %> saved by other session."))
      |> push_navigate(to: ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>_id}/edit")

    {:noreply, socket}
  end

  def handle_info({:resources_bulk_deleted, <%= schema.singular %>_ids, _meta}, socket) do
    if socket.assigns[:<%= schema.singular %>_id] in <%= schema.singular %>_ids do
      socket =
        socket
        |> put_flash(:info, dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted by other session."))
        |> redirect(to: ~p"<%= schema.route_prefix %>")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:resource_deleted, _<%= schema.singular %>_params, _meta}, socket) do
    socket =
      socket
      |> put_flash(:info, dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted by other session."))
      |> redirect(to: ~p"<%= schema.route_prefix %>")

    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    MandarinNotifications.log_unhandled_message(__MODULE__, msg)
    {:noreply, socket}
  end

  def handle_event("validate", %{"<%= schema.singular %>" => <%= schema.singular %>_params}, socket) do
     # Are we validating a form for a <%= schema.human_singular %> that already exists?
     case <%= schema.singular %>_params do
      %{"id" => <%= schema.singular %>_id} when <%= schema.singular %>_id not in ["", nil] ->
        # Subscribe to the <%= schema.human_singular %> resource we're editing.
        # Subscribe to the main channel to be notified if the resource is deleted.
        MandarinNotifications.subscribe("<%= schema.singular %>")
        MandarinNotifications.notify(
          "<%= schema.singular %>:#{<%= schema.singular %>_id}",
          {:draft_updated, <%= schema.singular %>_params, %{}}
        )

      _no_id ->
        :ok
    end

    update_draft_<%= schema.singular %>(<%= schema.singular %>_params, socket)
  end

  def handle_event("save", %{"<%= schema.singular %>" => <%= schema.singular %>_params}, socket) do
    # Are we saving a <%= schema.human_singular %> that already exists or are we creating a new one?
    case <%= schema.singular %>_params do
      %{"id" => <%= schema.singular %>_id} when <%= schema.singular %>_id not in ["", nil] ->
        update_<%= schema.singular %>(<%= schema.singular %>_id, <%= schema.singular %>_params, socket)

      _non_nil ->
        create_<%= schema.singular %>(<%= schema.singular %>_params, socket)
    end
  end

  defp create_<%= schema.singular %>(<%= schema.singular %>_params, socket) do
    current_user = socket.assigns[:current_user]

    case <%= inspect context.alias %>.can_create_<%= schema.singular %>(current_user) do
      :ok ->
        case <%= inspect context.alias %>.create_<%= schema.singular %>(<%= schema.singular %>_params) do
          {:ok, %<%= inspect schema.alias %>{} = <%= schema.singular %>} ->
            valid_changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)
            path = ~p"<%= schema.route_prefix %>/#{<%= schema.singular %>.id}/edit"
            message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> created successfully.")

            form =
              valid_changeset
              |> Map.put(:action, :update)
              |> to_form()

            socket =
              assign(socket,
                <%= schema.singular %>_id: <%= schema.singular %>.id,
                action: path,
                form: form
              )
              |> put_flash(:info, message)
              |> push_navigate(to: path)

            # Subscribe to the recently created <%= schema.human_singular %>;
            # No clients are connected, so don't emit a notification.
            # Subscribe to the main channel to be notified if the resource is deleted.
            MandarinNotifications.subscribe("<%= schema.singular %>")
            MandarinNotifications.subscribe("<%= schema.singular %>:#{<%= schema.singular %>.id}")

            # Notify sessions that are listening to the whole list
            MandarinNotifications.notify(
              "<%= schema.singular %>",
              {:resource_created, <%= schema.singular %>.id, %{}}
            )

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = maybe_invalid_changeset} ->
            socket =
              assign(socket,
                form: to_form(maybe_invalid_changeset)
              )

            {:noreply, socket}
        end

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't create <%= schema.human_singular %>.")
        {:noreply, handle_authorization_error(socket, message, error)}
    end
  end

  def update_<%= schema.singular %>(<%= schema.singular %>_id, <%= schema.singular %>_params, socket) do
    current_user = socket.assigns[:current_user]
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>_id)

    case <%= inspect context.alias %>.can_edit_<%= schema.singular %>(current_user, <%= schema.singular %>) do
      :ok ->
        case <%= inspect context.alias %>.update_<%= schema.singular %>(<%= schema.singular %>, <%= schema.singular %>_params) do
          {:ok, <%= schema.singular %>} ->
            # The <%= schema.human_singular %> already exists, and other clients may
            # have subscribed to the corresponding topic. Notify those clients.
            MandarinNotifications.notify(
              "<%= schema.singular %>:#{<%= schema.singular %>_id}",
              {:resource_updated, <%= schema.singular %>_params, %{}}
            )

            valid_changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)
            message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> saved successfully.")

            socket =
              assign(socket,
                <%= schema.singular %>_id: <%= schema.singular %>_id,
                form: to_form(valid_changeset)
              )
              |> put_flash(:info, message)

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = maybe_invalid_changeset} ->
            socket =
              assign(socket,
                <%= schema.singular %>_id: <%= schema.singular %>_id,
                form: to_form(maybe_invalid_changeset)
              )

            {:noreply, socket}
        end

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't edit <%= schema.human_singular %>.")
        {:noreply, handle_authorization_error(socket, message, error)}
    end
  end

  def update_draft_<%= schema.singular %>(<%= schema.singular %>_params, socket) do
    form =
      %<%= inspect schema.alias %>{}
      |> <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>_params)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  # Error rendering
  # ===============
  # You can override these if you want something custom.
  # This should be good enough for a starting point.

  @spec handle_authorization_error(Phoenix.Socket.t(), String.t(), {:error, atom()}) :: Phoenix.Socket.t()
  def handle_authorization_error(socket, message, {:error, _reason} = error) do
    access_message =
      case error do
        {:error, :unauthorized} ->
          dgettext("<%= context.basename %>", "Unauthorized access. Please login.")

        {:error, :forbidden} ->
          dgettext("<%= context.basename %>", "Access forbidden.")
      end

    full_message = access_message <> " " <> message

    # Give the user some feedback about why the action didn't work
    put_flash(socket, :error, full_message)
  end
end
