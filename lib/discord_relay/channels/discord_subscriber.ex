defmodule DiscordRelay.Channels.DiscordSubscriber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "discord_subscribers" do
    field :discord_channel, DiscordRelay.DiscordId
    field :announcements, :boolean, default: false
    belongs_to :channel, DiscordRelay.Channels.Channel

    timestamps()
  end

  @doc false
  def changeset(discord_subscriber, attrs) do
    discord_subscriber
    |> cast(attrs, [:discord_channel, :channel_id, :announcements])
    |> validate_required([:discord_channel, :channel_id, :announcements])
  end
end
