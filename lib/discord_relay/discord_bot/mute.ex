defmodule DiscordRelay.DiscordBot.Mute do
  @behaviour Nosedrum.Command

  alias Nostrum.Api
  alias DiscordRelay.Steam
  alias DiscordRelay.Bans
  alias DiscordRelay.BanCache

  @impl true
  def usage, do: ["mute <steam_id:string> [duration:number] [reason:string]"]

  @impl true
  def description, do: "Mute a steam ID for a duration"

  @impl true
  def predicates, do: [Nosedrum.Predicates.has_permission(:ban_members)]

  @impl true
  def command(msg, [steam_id]) do
    command(msg, [steam_id, "0", ""])
  end

  @impl true
  def command(msg, [steam_id, duration]) do
    command(msg, [steam_id, duration, ""])
  end

  @impl true
  def command(msg, [steam_id, duration | reason]) do
    case Integer.parse(duration) do
      {duration, ""} ->
        ban_steam_id(msg, steam_id, duration, Enum.join(reason, " "))
      _ ->
        Api.create_message!(msg.channel_id, "Invalid duration specified")
    end
  end

  @impl true
  def command(msg, _args) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "ℹ️ usage: #{usage()}")
  end

  def ban_steam_id(msg, steam_id, duration, reason) do
    duration_msg = if duration == 0 do
      "permantently"
    else
      "for #{duration} minutes"
    end

    steam_id = String.trim(steam_id)
    case Steam.steam_id_to_steam_id64(steam_id) do
      {:ok, community_id} ->
        expires = if duration == 0 do
          ~N[2200-01-01 23:59:59]
        else
          NaiveDateTime.utc_now() |> NaiveDateTime.add(duration * 60)
        end

        {:ok, steam_id3} = Steam.steam_id64_to_steam_id3(community_id)
        case Steam.profile_name(community_id) do
          {:ok, profile_name} ->
            {:ok, ban} = Bans.create_ban(%{steamid: steam_id3, reason: reason, expires: expires, name: to_string(profile_name)})
            BanCache.add_ban(ban.steamid, expires)

            {:ok, _msg} = Api.create_message(msg.channel_id, "👌 muted #{profile_name} #{duration_msg}")
          _ ->
            {:ok, _} = Bans.create_ban(%{steamid: steam_id3, reason: reason, expires: expires, name: steam_id})
            {:ok, _msg} = Api.create_message(msg.channel_id, "👌 muted #{steam_id} #{duration_msg}")
        end
      _ ->
        Api.create_message(msg.channel_id, "Error parsing SteamID")
    end
  end
end
