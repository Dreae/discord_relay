defmodule DiscordRelay.Repo.Migrations.CreateServerSubscribers do
  use Ecto.Migration

  def change do
    create table(:server_subscribers) do
      add :channel_id, references(:channels, on_delete: :nothing)
      add :server_id, references(:servers, on_delete: :nothing)

      timestamps()
    end

    create index(:server_subscribers, [:channel_id])
    create index(:server_subscribers, [:server_id])
  end
end
