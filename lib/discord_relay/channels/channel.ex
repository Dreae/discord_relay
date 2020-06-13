defmodule DiscordRelay.Channels.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :name, :string
    field :flags, DiscordRelay.Channels.ChannelFlag
    has_many :discord_subscribers, DiscordRelay.Channels.DiscordSubscriber
    has_many :server_subscribers, DiscordRelay.Channels.ServerSubscriber
    has_many :servers, through: [:server_subscribers, :server]

    timestamps()
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :flags])
    |> validate_required([:name])
  end
end
