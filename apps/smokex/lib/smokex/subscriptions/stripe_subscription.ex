defmodule Smokex.Subscriptions.StripeSubscription do
  @moduledoc """
  Module that represents a Stripe subscription.
  """
  use Ecto.Schema

  alias Smokex.Users.User

  @typedoc """
  Represents a [stripe subscription](https://stripe.com/docs/api/subscriptions):

  * `customer_id`: The [stripe customer](https://stripe.com/docs/api/customers/object).
  * `stripe_id`: The [stripe subscription](https://stripe.com/docs/api/subscriptions/object).
  * `user`: The user who the subscription belongs to.
  """
  @type t :: %__MODULE__{
          customer_id: String.t(),
          subscription_id: String.t(),
          user: User.t()
        }

  @required_fields [:customer_id]
  @optional_fields [:subscription_id]

  @schema_fields @optional_fields ++ @required_fields

  schema "stripe_subscriptions" do
    field(:customer_id, :string, null: false)
    field(:subscription_id, :string, null: true)

    belongs_to(:user, User)
  end

  @spec create_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(params, @required_fields)
    |> Ecto.Changeset.put_assoc(:user, params[:user])
    |> Ecto.Changeset.assoc_constraint(:user)
  end

  @spec update_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @optional_fields)
  end
end
