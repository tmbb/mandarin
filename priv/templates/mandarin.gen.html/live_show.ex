defmodule <%= inspect Module.concat([context.web_module, schema.web_namespace, schema.alias]) %>LiveShow do
  use <%= inspect context.web_module %>.MandarinWeb, :live_view
  alias <%= inspect context.base_module %>.MandarinNotifications

  import <%= inspect context.web_module %>.<%= inspect context.alias %>.<%= inspect schema.alias %>HTML
  alias <%= inspect context.module %>

  def mount(%{"id" => <%= schema.singular %>_id}, _session, socket) do
    current_user = socket.assigns[:current_user]
    # Get the <%= schema.human_singular %> by ID
    <%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>_id)

    case <%= inspect context.alias %>.can_read_<%= schema.singular %>(current_user, <%= schema.singular %>) do
      :ok ->
        # Subscribe to the <%= schema.human_singular %> resource we're editing.
        # Subscribe to the main channel to be notified if the resource
        # is bulk-deleted.
        MandarinNotifications.subscribe("<%= schema.singular %>")
        MandarinNotifications.subscribe("<%= schema.singular %>:#{<%= schema.singular %>.id}")

        socket = assign(socket, :<%= schema.singular %>, <%= schema.singular %>)
        {:ok, socket}

      {:error, _reason} = error ->
        message = dgettext("<%= context.basename %>", "Can't see <%= schema.human_singular %>.")
        {:error, handle_authorization_error(socket, message, error)}
    end
  end

  def render(assigns) do
    <%= schema.singular %>_live_show(assigns)
  end

  # Handle notifications from other clients editing the <%= schema.human_singular %>.
  # These handlers are not activated if the client has been edited by the same process.

  def handle_info({:resource_updated, %{"id" => <%= schema.singular %>_id} = _<%= schema.singular %>_params, _meta}, socket) do
    updated_<%= schema.singular %> = <%= inspect context.alias %>.get_<%= schema.singular %>!(<%= schema.singular %>_id)

    case updated_<%= schema.singular %> == socket.assigns[:<%= schema.singular %>] do
      true ->
        {:noreply, socket}

      false ->
        message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> saved by other session.")

        socket =
          socket
          |> put_flash(:info, message)
          |> assign(:<%= schema.singular %>, updated_<%= schema.singular %>)

        {:noreply, socket}
    end
  end

  def handle_info({:resources_bulk_deleted, <%= schema.singular %>_ids, _meta}, socket) do
    if socket.assigns[:<%= schema.singular %>_id] in <%= schema.singular %>_ids do
      message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted by other session.")

      socket =
        socket
        |> put_flash(:info, message)
        |> redirect(to: ~p"<%= schema.route_prefix %>")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:resource_deleted, _<%= schema.singular %>_params, _meta}, socket) do
    message = dgettext("<%= context.basename %>", "<%= schema.human_singular %> deleted by other session.")

    socket =
      socket
      |> put_flash(:info, message)
      |> redirect(to: ~p"<%= schema.route_prefix %>")

    {:noreply, socket}
  end

  def handle_info({:draft_updated, _params, _meta}, socket) do
    {:noreply, socket}
  end

  def handle_info(event, socket) do
    MandarinNotifications.log_unhandled_message(__MODULE__, event)
    {:noreply, socket}
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
