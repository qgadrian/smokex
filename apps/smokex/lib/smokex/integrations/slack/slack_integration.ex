defmodule Smokex.Integrations.Slack.SlackIntegration do
  use Ecto.Schema

  alias Smokex.Organizations.Organization
  alias Smokex.Integrations.Slack.SlackIntegrationPreferences

  @schema_fields [:token, :user_id]

  @typedoc """
  A Slack Oauth2 token associated to a organization.
  """
  @type t :: %__MODULE__{
          token: String.t(),
          organization_id: number,
          options: SlackIntegrationPreferences.t()
        }

  schema "slack_integrations" do
    field(:token, :string, null: false)

    embeds_one(:options, SlackIntegrationPreferences, on_replace: :update)

    belongs_to(:organization, Organization)

    timestamps()
  end

  @spec create_changeset(__MODULE__.t(), map) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create_changeset(changeset, params \\ %{}) do
    # If no options is provided the embeded schema needs to be present. Since
    # there is no default fields the default attrs need to be send instead.
    params = Map.put_new(params, :options, %{post_to_channel: ""})

    changeset
    |> Smokex.Repo.preload(:organization)
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@schema_fields)
    |> Ecto.Changeset.cast_embed(:options, required: true)
    |> Ecto.Changeset.cast_assoc(:organization)
    |> Ecto.Changeset.assoc_constraint(:organization)
  end
end
