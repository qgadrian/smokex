defmodule Smokex.Integrations.Slack.SlackIntegrationPreferences do
  @moduledoc """
  Represents the integration options for Slack.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          channel_to_post: [String.t()],
          post_on_success: boolean,
          post_on_fail: boolean
        }

  @schema_fields [:channel_to_post, :post_on_success, :post_on_fail]

  @primary_key false
  embedded_schema do
    field :channel_to_post, :string, default: nil
    field :post_on_success, :boolean, default: false
    field :post_on_fail, :boolean, default: true
  end

  @spec changeset(__MODULE__.t(), map) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@schema_fields)
  end
end
