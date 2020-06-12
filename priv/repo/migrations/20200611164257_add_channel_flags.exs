defmodule DiscordRelay.Repo.Migrations.AddChannelFlags do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :flags, :smallint, default: 0
    end
  end
end
