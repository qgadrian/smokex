# TODO how can mix the pow behaviour with a single mail sender module
defmodule SmokexWeb.Pow.Mailer do
  use Pow.Phoenix.Mailer
  # TODO configure local adapter on dev profile
  use Swoosh.Mailer, otp_app: :smokex_web
  use Phoenix.Swoosh, view: SmokexWeb.EmailView, layout: {SmokexWeb.LayoutView, :email}

  import Swoosh.Email

  require Logger

  @impl Pow.Phoenix.Mailer
  def cast(%{user: user, subject: subject, text: text, html: html}) do
    from_email = "hello@smokex.io"

    %Swoosh.Email{}
    |> to({"", user.email})
    |> from({"Smokex", from_email})
    |> subject(subject)
    |> html_body(html)
    |> text_body(text)
  end

  def cast(%{user: user, subject: subject, template: template}, opts \\ []) do
    from_email = Keyword.get(opts, :from, "hello@smokex.io")
    assigns = Keyword.get(opts, :assigns, %{})

    %Swoosh.Email{}
    |> to({"", user.email})
    |> from({"Smokex", from_email})
    |> subject(subject)
    |> render_body(template, assigns)
  end

  @impl Pow.Phoenix.Mailer
  def process(email) do
    # An asynchronous process should be used here to prevent enumeration
    # attacks. Synchronous e-mail delivery can reveal whether a user already
    # exists in the system or not.

    Task.start(fn ->
      email
      |> deliver()
      |> log_warnings()
    end)

    :ok
  end

  defp log_warnings({:error, reason}) do
    Logger.warn("Mailer backend failed with: #{inspect(reason)}")
  end

  defp log_warnings({:ok, response}), do: {:ok, response}
end
