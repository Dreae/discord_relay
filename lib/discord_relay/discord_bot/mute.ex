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
      "permanently"
    else
      "for #{duration} minutes"
    end

    steam_id = String.trim(steam_id)
    case Steam.steam_id_to_steam_id64(steam_id) do
      {:ok, community_id} ->
        expires = if duration == 0 do
          NaiveDateTime.utc_now() |> NaiveDateTime.add(6_311_520_000)
        else
          NaiveDateTime.utc_now() |> NaiveDateTime.add(duration * 60)
        end

        {:ok, steam_id3} = Steam.steam_id64_to_steam_id3(community_id)
        profile_name = case Steam.profile_name(community_id) do
          {:ok, profile_name} -> to_string(profile_name)
          _ -> steam_id
        end

        {:ok, ban} = create_ban(%{steamid: steam_id3, reason: reason, expires: expires, name: to_string(profile_name)})
        BanCache.add_ban(ban.steamid, expires)

        Api.create_message!(msg.channel_id, "✔️ muted #{profile_name} #{duration_msg}")
      _ ->
        Api.create_message!(msg.channel_id, "Error parsing SteamID")
    end
  end

  def create_ban(ban) do
    case Bans.find_ban(ban.steamid) do
      nil -> Bans.create_ban(ban)
      db_ban ->
        {:ok, _ } = Bans.delete_ban(db_ban)
        Bans.create_ban(ban)
    end
  end
end
