defmodule DiscordRelay.Repo.Migrations.CreateBans do
  use Ecto.Migration

  def change do
    create table(:bans) do
      add :steamid, :string
      add :name, :string
      add :expires, :naive_datetime
      add :reason, :string

      timestamps()
    end

    create unique_index(:bans, [:steamid])
  end
end
