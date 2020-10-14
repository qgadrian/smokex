defmodule Smokex.Integrations.Slack.SlackIntegrationPreferences do
  @moduledoc """
  Represents the integration options for Slack.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          post_to_channel: String.t(),
          post_on_run: boolean,
          post_on_success: boolean,
          post_on_fail: boolean
        }

  @required_fields [:post_on_success, :post_on_fail, :post_on_run]
  @optional_fields [:post_to_channel]

  @schema_fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :post_to_channel, :string, default: ""
    field :post_on_success, :boolean, default: false
    field :post_on_run, :boolean, default: false
    field :post_on_fail, :boolean, default: true
  end

  @spec changeset(__MODULE__.t(), map) :: Ecto.Changeset.t(__MODULE__.t())
  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
  end
end
