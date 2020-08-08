defmodule SmokexWeb.Tracer do
  @moduledoc """
  Module used to setup tracing information.

  * Updates Sentry context
  * Updates the Logger process metadata
  """

  alias Smokex.Users.User

  @doc """
  Initializes the trace for the user.
  """
  @spec trace_user(User.t() | number) :: :ok
  def trace_user(%User{id: id}) do
    Sentry.Context.set_user_context(%{user_id: id})
    Logger.metadata(user_id: id)
  end

  def trace_user(id) when is_number(id) do
    Sentry.Context.set_user_context(%{user_id: id})
    Logger.metadata(user_id: id)
  end

  @doc """
  Initializes the trace for a Stripe event.
  """
  @spec trace_stripe_event(%{type: String.t()}) :: :ok
  def trace_stripe_event(%{type: stripe_event_type}) do
    Sentry.Context.set_tags_context(%{stripe_event: stripe_event_type})
    Logger.metadata(stripe_event: stripe_event_type)
  end

  @doc """
  Initializes the trace for a Stripe customer.
  """
  @spec trace_stripe_customer(customer_id :: String.t()) :: :ok
  def trace_stripe_customer(customer_id) when is_binary(customer_id) do
    Sentry.Context.set_tags_context(%{stripe_customer_id: customer_id})
    Logger.metadata(stripe_customer_id: customer_id)
  end

  @doc """
  Initializes the trace for a Stripe subscription.
  """
  @spec trace_stripe_subscription(subscription_id :: String.t()) :: :ok
  def trace_stripe_subscription(subscription_id) when is_binary(subscription_id) do
    Sentry.Context.set_tags_context(%{stripe_subscription_id: subscription_id})
    Logger.metadata(stripe_subscription_id: subscription_id)
  end
end
