defmodule <%= inspect context.base_module %>.MandarinNotifications do
  alias Phoenix.PubSub
  require Logger

  @doc """
  Subscribe to a topic to receive notifications related
  to the corresponding resource.
  """
  def subscribe(topic) do
    PubSub.subscribe(<%= inspect context.base_module %>.PubSub, topic)
  end

  @doc """
  Unsubscribe to a topic to receive notifications related
  to the corresponding resource.
  """
  def unsubscribe(topic) do
    PubSub.unsubscribe(<%= inspect context.base_module %>.PubSub, topic)
  end

  @doc """
  Notify subscribers of a topic that an event has happened.
  """
  def notify(topic, msg) do
    PubSub.broadcast_from(<%= inspect context.base_module %>.PubSub, self(), topic, msg)
  end

  @doc """
  Log unhandled messages.
  """
  def log_unhandled_message(module, msg) do
    Logger.warning("#{module} - unhandled message: #{inspect(msg)}")
  end
end
