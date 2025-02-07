defmodule <%= module %> do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Mandarin.Presence`](https://hexdocs.pm/phoenix/Mandarin.Presence.html)
  docs for more details.
  """
  use Mandarin.Presence,
    otp_app: <%= inspect otp_app %>,
    pubsub_server: <%= inspect pubsub_server %>
end
