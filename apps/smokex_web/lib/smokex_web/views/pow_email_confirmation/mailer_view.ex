defmodule SmokexWeb.PowEmailConfirmation.MailerView do
  use SmokexWeb, :mailer_view

  def subject(:email_confirmation, _assigns), do: "Confirm your email address"
end
