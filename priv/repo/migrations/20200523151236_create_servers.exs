defmodule DiscordRelay.Repo.Migrations.CreateServers do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add :name, :string
      add :key_id, :string
      add :key, :string

      timestamps()
    end

    create index(:servers, [:key_id])
  end
end
