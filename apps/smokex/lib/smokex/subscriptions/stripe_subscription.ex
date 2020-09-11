defmodule Smokex.Subscriptions.StripeSubscription do
  @moduledoc """
  Module that represents a Stripe subscription.
  """
  use Ecto.Schema

  alias Smokex.Organizations.Organization

  @typedoc """
  Represents a [stripe subscription](https://stripe.com/docs/api/subscriptions):

  * `customer_id`: The [stripe customer](https://stripe.com/docs/api/customers/object).
  * `stripe_id`: The [stripe subscription](https://stripe.com/docs/api/subscriptions/object).
  * `organization`: The organization who the subscription belongs to.
  """
  @type t :: %__MODULE__{
          customer_id: String.t(),
          subscription_id: String.t(),
          organization: Organization.t()
        }

  @required_fields [:customer_id]
  @optional_fields [:subscription_id, :organization_id]
  @updatable_fields [:subscription_id]

  @schema_fields @optional_fields ++ @required_fields

  schema "stripe_subscriptions" do
    field(:customer_id, :string, null: false)
    field(:subscription_id, :string, null: true)

    belongs_to(:organization, Organization)

    timestamps()
  end

  @spec create_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> maybe_put_organization(params)
  end

  @spec update_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @updatable_fields)
  end

  #
  # Private functions
  #

  defp maybe_put_organization(changeset, %{organization: nil}), do: changeset

  defp maybe_put_organization(changeset, %{organization: %Organization{} = organization}) do
    changeset
    |> Ecto.Changeset.put_assoc(:organization, organization)
    |> Ecto.Changeset.assoc_constraint(:organization)
  end

  defp maybe_put_organization(changeset, _params), do: changeset
end
