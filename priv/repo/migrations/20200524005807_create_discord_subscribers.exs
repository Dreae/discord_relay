defmodule DiscordRelay.Repo.Migrations.CreateDiscordSubscribers do
  use Ecto.Migration

  def change do
    create table(:discord_subscribers) do
      add :channel_id, references(:channels, on_delete: :nothing)
      add :discord_channel, :binary
      add :announcements, :boolean, default: false, null: false

      timestamps()
    end

    create index(:discord_subscribers, [:discord_channel])
    create index(:discord_subscribers, [:channel_id])
  end
end
