defmodule SmokexWeb.Tracer do
  @moduledoc """
  Module used to setup tracing information.

  * Updates Sentry context
  * Updates the Logger process metadata
  """

  alias Smokex.PlanExecution
  alias Smokex.Users.User
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization

  @doc """
  Initializes the trace for the user.

  This function also sets the trace context for the user's organization.
  """
  @spec trace_user(User.t()) :: :ok
  def trace_user(%User{id: user_id} = user) do
    {:ok, %Organization{} = organization} = Organizations.get_organization(user)
    __MODULE__.trace_organization(organization)

    Sentry.Context.set_user_context(%{user_id: user_id})
    Logger.metadata(user_id: user_id)
  end

  @spec trace_organization(Organization.t()) :: :ok
  def trace_organization(%Organization{id: organization_id}) do
    Sentry.Context.set_user_context(%{organization_id: organization_id})
    Logger.metadata(organization_id: organization_id)
  end

  @doc """
  Initializes the trace for the execution.
  """
  @spec trace_plan_execution(PlanExecution.t()) :: :ok
  def trace_plan_execution(%PlanExecution{
        id: plan_execution_id,
        trigger_user_id: trigger_user_id,
        plan_definition_id: plan_definition_id
      }) do
    Sentry.Context.set_tags_context(%{
      trigger_user_id: trigger_user_id,
      plan_execution_id: plan_execution_id,
      plan_definition_id: plan_definition_id
    })

    Logger.metadata(
      trigger_user_id: trigger_user_id,
      plan_execution_id: plan_execution_id,
      plan_definition_id: plan_definition_id
    )
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
