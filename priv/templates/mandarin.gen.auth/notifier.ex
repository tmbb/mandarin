defmodule <%= inspect context.module %>.<%= inspect schema.alias %>Notifier do
  import Swoosh.Email
  import <%= inspect context.web_module %>.Gettext

  alias <%= inspect context.base_module %>.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"<%= inspect context.base_module %>", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(<%= schema.singular %>, url) do
    title = dgettext("mandarin.<%= schema.context_underscore %>", "Confirmation instructions")

    message = dgettext("mandarin.<%= schema.context_underscore %>", """

      ==============================

      Hi %{<%= schema.singular %>_email},

      You can confirm your account by visiting the URL below:

      %{url}

      If you didn't create an account with us, please ignore this.

      ==============================
      """, <%= schema.singular %>_email: <%= schema.singular %>.email, url: url)

    deliver(<%= schema.singular %>.email, title, message)
  end

  @doc """
  Deliver instructions to reset a <%= schema.singular %> password.
  """
  def deliver_reset_password_instructions(<%= schema.singular %>, url) do
    title = dgettext("mandarin.<%= schema.context_underscore %>", "Reset password instructions")

    message = dgettext("mandarin.<%= schema.context_underscore %>", """

      ==============================

      Hi %{<%= schema.singular %>_email},

      You can reset your password by visiting the URL below:

      %{url}

      If you didn't request this change, please ignore this.

      ==============================
      """, <%= schema.singular %>_email: <%= schema.singular %>.email, url: url)

    deliver(<%= schema.singular %>.email, title, message)
  end

  @doc """
  Deliver instructions to update a <%= schema.singular %> email.
  """
  def deliver_update_email_instructions(<%= schema.singular %>, url) do
    title = dgettext("mandarin.<%= schema.context_underscore %>", "Update email instructions")

    message = dgettext("mandarin.<%= schema.context_underscore %>", """

      ==============================

      Hi %{<%= schema.singular %>_email},

      You can change your email by visiting the URL below:

      %{url}

      If you didn't request this change, please ignore this.

      ==============================
      """, <%= schema.singular %>_email: <%= schema.singular %>.email, url: url)

    deliver(<%= schema.singular %>.email, title, message)
  end
end
