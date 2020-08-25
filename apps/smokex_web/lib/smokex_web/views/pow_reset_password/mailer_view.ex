defmodule SmokexWeb.PowResetPassword.MailerView do
  use SmokexWeb, :mailer_view

  def subject(:reset_password, _assigns), do: "Reset password link"
end
