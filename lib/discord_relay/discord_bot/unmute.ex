defmodule DiscordRelay.DiscordBot.Unmute do
  @behaviour Nosedrum.Command

  alias Nostrum.Api
  alias DiscordRelay.Bans
  alias DiscordRelay.BanCache
  alias DiscordRelay.Steam

  @impl true
  def usage, do: ["unmute <steam_id:string>"]

  @impl true
  def description, do: "Unmute a steam ID"

  @impl true
  def predicates, do: [Nosedrum.Predicates.has_permission(:ban_members)]

  @impl true
  def command(msg, [steam_id]) do
    steam_id = String.trim(steam_id)
    case Bans.find_ban(steam_id) do
      nil ->
        Api.create_message!(msg.channel_id, "Unable to find mute")
      ban ->
        case Bans.delete_ban(ban) do
          {:ok, _} ->
            BanCache.remove_ban(ban.steamid)
            case Steam.profile_name(steam_id) do
              {:ok, profile_name} ->
                Api.create_message!(msg.channel_id, "✔️ unmuted #{profile_name}")
              _ ->
                Api.create_message!(msg.channel_id, "✔️ unmuted #{steam_id}")
            end
          _ ->
            Api.create_message!(msg.channel_id, "Error deleting mute")
        end
    end
  end

  @impl true
  def command(msg, _args) do
    Api.create_message!(msg.channel_id, "ℹ️ usage: #{usage()}")
  end
end
