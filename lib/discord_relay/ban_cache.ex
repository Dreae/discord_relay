defmodule DiscordRelay.BanCache do
  use GenServer

  alias DiscordRelay.Bans

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def add_ban(steam_id, expires) do
    :ets.insert(:discord_relay_ban_cache, {steam_id, expires})
  end

  def remove_ban(steam_id) do
    :ets.delete(:discord_relay_ban_cache, steam_id)
  end

  def is_banned(steam_id) do
    case :ets.lookup(:discord_relay_ban_cache, steam_id) do
      [{steam_id, expires}] ->
        if NaiveDateTime.compare(NaiveDateTime.utc_now(), expires) == :gt do
          remove_ban(steam_id)
          false
        else
          true
        end
      _ ->
        case Bans.find_ban(steam_id) do
          nil -> false
          ban ->
            if NaiveDateTime.compare(NaiveDateTime.utc_now(), ban.expires) == :gt do
              {:ok, _} = Bans.delete_ban(ban)
              false
            else
              true
            end
        end
    end
  end

  def init(_args) do
    tid = :ets.new(:discord_relay_ban_cache, [:named_table, :public, read_concurrency: true])

    {:ok, tid}
  end

  def handle_call(:tid, _, tid) do
    {:reply, tid, tid}
  end
end
