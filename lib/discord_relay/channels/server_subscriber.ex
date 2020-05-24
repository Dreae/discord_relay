defmodule DiscordRelay.Channels.ServerSubscriber do
  use Ecto.Schema
  import Ecto.Changeset

  schema "server_subscribers" do
    belongs_to :channel, DiscordRelay.Channels.Channel
    belongs_to :server, DiscordRelay.Servers.Server

    timestamps()
  end

  @doc false
  def changeset(server_subscriber, attrs) do
    server_subscriber
    |> cast(attrs, [:server_id, :channel_id])
    |> validate_required([:server_id, :channel_id])
  end
end
