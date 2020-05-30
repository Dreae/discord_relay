defmodule DiscordRelay.Webhooks.DiscordWebHook do
  use Ecto.Schema
  import Ecto.Changeset
  alias DiscordRelay.DiscordId

  schema "discord_hooks" do
    belongs_to :discord_subscriber, DiscordRelay.Channels.DiscordSubscriber
    field :webhook_id, DiscordId
    field :webhook_token, :string

    timestamps()
  end

  @doc false
  def changeset(discord_web_hook, attrs) do
    discord_web_hook
    |> cast(attrs, [:discord_subscriber_id, :webhook_id, :webhook_token])
    |> validate_required([:discord_subscriber_id, :webhook_id, :webhook_token])
    |> unique_constraint(:discord_subscriber_id)
    |> unique_constraint(:webhook_id)
  end
end
