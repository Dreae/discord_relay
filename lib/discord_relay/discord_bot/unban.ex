defmodule DiscordRelay.DiscordBot.Unban do
  @behaviour Nosedrum.Command

  alias Nostrum.Api
  alias DiscordRelay.Bans
  alias DiscordRelay.BanCache

  @impl true
  def usage, do: ["unban <steam_id:string>"]

  @impl true
  def description, do: "Unban a steam ID"

  @impl true
  def predicates, do: [Nosedrum.Predicates.has_permission(:ban_members)]

  @impl true
  def command(msg, [steam_id]) do
    case Bans.find_ban(steam_id) do
      nil ->
        Api.create_message!(msg.channel_id, "Unable to find ban")
      ban ->
        case Bans.delete_ban(ban) do
          {:ok, _} ->
            BanCache.remove_ban(ban.steamid)
            Api.create_message!(msg.channel_id, "👌 unbanned #{steam_id}")
          _ ->
            Api.create_message!(msg.channel_id, "Error deleting ban")
        end
    end
  end

  @impl true
  def command(msg, _args) do
    Api.create_message!(msg.channel_id, "ℹ️ usage: #{usage()}")
  end
end
