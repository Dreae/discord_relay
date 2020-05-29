defmodule DiscordRelay.Bans.Ban do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bans" do
    field :expires, :naive_datetime
    field :steamid, :string
    field :name, :string
    field :reason, :string

    timestamps()
  end

  @doc false
  def changeset(ban, attrs) do
    ban
    |> cast(attrs, [:steamid, :expires, :name, :reason])
    |> validate_required([:steamid, :expires, :name])
    |> unique_constraint(:steamid)
  end
end
