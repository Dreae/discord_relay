defmodule DiscordRelay.Repo.Migrations.CreateDiscordHooks do
  use Ecto.Migration

  def change do
    create table(:discord_hooks) do
      add :discord_subscriber_id, references(:discord_subscribers, on_delete: :nothing)
      add :webhook_id, :binary
      add :webhook_token, :string

      timestamps()
    end

    create unique_index(:discord_hooks, [:discord_subscriber_id])
    create unique_index(:discord_hooks, [:webhook_id])
  end
end
