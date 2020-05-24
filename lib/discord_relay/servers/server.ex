defmodule DiscordRelay.Servers.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "servers" do
    field :key, :string
    field :key_id, :string
    field :name, :string
    has_many :subscriptions, DiscordRelay.Channels.ServerSubscriber
    has_many :channels, through: [:subscriptions, :channel]

    timestamps()
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :key_id, :key])
    |> validate_required([:name, :key_id, :key])
  end
end
