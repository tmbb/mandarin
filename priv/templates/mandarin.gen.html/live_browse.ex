defmodule <%= inspect Module.concat([context.web_module, schema.web_namespace, schema.alias]) %>LiveBrowse do
  use <%= inspect context.web_module %>.MandarinWeb, :live_view
  alias <%= inspect context.base_module %>.MandarinNotifications

  import <%= inspect context.web_module %>.<%= inspect context.alias %>.<%= inspect schema.alias %>HTML
  alias <%= inspect context.module %>

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    case <%= inspect context.alias %>.can_browse_<%= schema.plural %>(current_user) do
      :ok ->
        {:ok, socket, temporary_assigns: [<%= schema.plural %>: nil]}

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't browse <%= schema.human_plural %>.")
        {:error, handle_authorization_error(socket, message, error)}
    end
  end

  def handle_params(params, _uri, socket) do
    current_user = socket.assigns[:current_user]
    {:ok, {<%= schema.plural %>, meta}} = <%= inspect context.alias %>.list_<%= schema.plural %>(params)

    MandarinNotifications.subscribe("<%= schema.singular %>")
    for <%= schema.singular %> <- <%= schema.plural %> do
      MandarinNotifications.subscribe("<%= schema.singular %>:#{<%= schema.singular %>.id}")
    end

    socket =
      assign(socket,
        <%= schema.plural %>: <%= schema.plural %>,
        meta: meta,
        id_marked_for_deletion: nil,
        ids_marked_for_bulk_action: [],
        current_user: current_user
      )

    {:noreply, socket}
  end

  def render(assigns) do
    <%= schema.singular %>_live_browse(assigns)
  end

  # Handle notifications from other clients editing the <%= schema.human_singular %>.
  # These handlers are not activated if the client has been edited by the same process.

  def handle_info({:resource_created, _id, _meta}, socket) do
    message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> created in other session.")

    socket =
      socket
      |> put_flash(:info, message)
      |> push_patch(to: "<%= schema.route_prefix %>")

    {:noreply, socket}
  end

  def handle_info({:resource_deleted, id, _meta}, socket) do
    message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted in other session.")

    socket =
      socket
      |> put_flash(:info, message)
      |> push_patch(to: "<%= schema.route_prefix %>")

    MandarinNotifications.unsubscribe("<%= schema.singular %>:#{id}")

    {:noreply, socket}
  end

  def handle_info({:resources_bulk_deleted, <%= schema.singular %>_ids, _meta}, socket) do
    message = dgettext("<%= context.basename %>", "<%= schema.human_plural %> deleted in other session.")

    socket =
      socket
      |> put_flash(:info, message)
      |> push_patch(to: "<%= schema.route_prefix %>")

    for id <- <%= schema.singular %>_ids do
      MandarinNotifications.unsubscribe("<%= schema.singular %>:#{id}")
    end

    {:noreply, socket}
  end

  def handle_info({:resource_updated, _<%= schema.singular %>_params, _meta}, socket) do
    # The :resource_updated event is only sent to the specific channel of the event,
    # which means we don't need to look at the id to see if it's the right id.
    message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> saved by other session.")

    socket =
      socket
      |> put_flash(:info, message)
      |> push_patch(to: ~p"<%= schema.route_prefix %>")

    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    MandarinNotifications.log_unhandled_message(__MODULE__, msg)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => <%= schema.singular %>_id}, socket) do
    # Store the list of ids to delete, but await confirmation
    socket = assign(socket, id_marked_for_deletion: <%= schema.singular %>_id)
    {:noreply, socket}
  end

  def handle_event("confirm_delete", _params, socket) do
    current_user = socket.assigns[:current_user]
    <%= schema.singular %>_id = socket.assigns[:id_marked_for_deletion]

    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>_id)

    case <%= inspect context.alias %>.can_delete_<%= schema.singular %>(current_user, <%= schema.singular %>) do
      :ok ->
        {:ok, _<%= schema.singular %>} = <%= inspect context.alias %>.delete_<%= schema.singular %>(<%= schema.singular %>)

        message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted successfully.")

        socket =
          socket
          |> put_flash(:info, message)
          |> push_patch(to: ~p"<%= schema.route_prefix %>")

        MandarinNotifications.notify(
          "<%= schema.singular %>:#{<%= schema.singular %>.id}",
          {:resource_deleted, <%= schema.singular %>.id, %{}}
        )

        MandarinNotifications.unsubscribe("<%= schema.singular %>:#{<%= schema.singular %>.id}")

        {:noreply, socket}

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't delete <%= schema.human_singular %>.")
        handle_authorization_error(socket, message, error)
    end
  end

  def handle_event("selected_for_bulk_action", params, socket) do
    selected_ids = Map.get(params, "selected", [])
    socket = assign(socket, ids_marked_for_bulk_action: selected_ids)
    {:noreply, socket}
  end

  def handle_event("bulk_action", %{"action" => "bulk_delete"} = params, socket) do
    ids = Map.get(params, "selected", [])
    # Store the list of ids to delete, but await confirmation
    socket = assign(socket, ids_marked_for_bulk_action: ids)
    {:noreply, socket}
  end

  def handle_event("confirm_bulk_delete", _params, socket) do
    current_user = socket.assigns[:current_user]
    <%= schema.singular %>_ids = socket.assigns[:ids_marked_for_bulk_action]

    case <%= inspect context.alias %>.can_bulk_delete_<%= schema.plural %>(current_user, <%= schema.singular %>_ids) do
      :ok ->
        {_n, _<%= schema.plural %>} = <%= inspect context.alias %>.bulk_delete_<%= schema.plural %>(<%= schema.singular %>_ids)

        message = dgettext("<%= context.basename %>", "<%= schema.human_plural %> deleted successfully.")

        socket =
          socket
          |> put_flash(:info, message)
          |> push_navigate(to: ~p"<%= schema.route_prefix %>")

        for id <- <%= schema.singular %>_ids do
          MandarinNotifications.notify(
            "<%= schema.singular %>:#{id}",
            {:resource_deleted, id, %{}}
          )

          MandarinNotifications.unsubscribe("<%= schema.singular %>:#{id}")
        end

        {:noreply, socket}

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't delete <%= schema.human_singular %>.")
        handle_authorization_error(socket, message, error)
    end
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
