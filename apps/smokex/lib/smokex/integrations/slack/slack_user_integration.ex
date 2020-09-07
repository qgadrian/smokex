defmodule Smokex.Integrations.Slack.SlackUserIntegration do
  use Ecto.Schema

  alias Smokex.Users.User
  alias Smokex.Integrations.Slack.SlackIntegrationPreferences

  @schema_fields [:token, :user_id]

  @typedoc """
  A Slack Oauth2 token associated to a user.
  """
  @type t :: %__MODULE__{
          token: String.t(),
          user_id: number,
          options: SlackIntegrationPreferences.t()
        }

  schema "slack_users_integrations" do
    field(:token, :string, null: false)
    embeds_one(:options, SlackIntegrationPreferences, on_replace: :update)

    belongs_to(:user, User)

    timestamps()
  end

  @spec create_changeset(__MODULE__.t(), map) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create_changeset(changeset, params \\ %{}) do
    changeset
    |> Smokex.Repo.preload(:user)
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@schema_fields)
    |> Ecto.Changeset.cast_embed(:options, required: true)
    |> Ecto.Changeset.cast_assoc(:user)
    |> Ecto.Changeset.assoc_constraint(:user)
  end
end
