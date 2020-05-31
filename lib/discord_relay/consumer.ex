defmodule DiscordRelay.Consumer do
  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nosedrum.Storage.ETS, as: CommandStorage
  use Nostrum.Consumer

  alias DiscordRelay.Channels

  require Logger

  @commands %{
    "mute" => DiscordRelay.DiscordBot.Mute,
    "unmute" => DiscordRelay.DiscordBot.Unmute
  }

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def handle_event({:READY, _data, _ws_state}) do
    Enum.each(@commands, fn {name, cog} -> CommandStorage.add_command({name}, cog) end)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    unless msg.author.bot do
      CommandInvoker.handle_message(msg, CommandStorage)
      cached_channels = fetch_channel(msg.channel_id)
      Enum.map(cached_channels, fn (channel) ->
        if channel.announcements do
          DiscordRelay.ChannelManager.send_announcement(channel.channel_id, msg.author.username, msg.content)
        else
          {:ok, guild} = Nostrum.Cache.GuildCache.get(msg.guild_id)
          DiscordRelay.ChannelManager.send_discord_message(channel.channel_id, guild.name, msg.author.username, msg.content)
        end
      end)
    end
  end

  def handle_event(_event) do
    :noop
  end

  def fetch_channel(channel_id) do
    case :ets.lookup(:discord_relay_blocked_channels, channel_id) do
      [] ->
        cache_get(channel_id)
      [{^channel_id, expires}] ->
        if NaiveDateTime.compare(NaiveDateTime.utc_now(), expires) == :gt do
          cache_get(channel_id)
        else
          []
        end
    end
  end

  def cache_get(channel_id) do
    case :ets.lookup(:discord_relay_channels, channel_id) do
      [{^channel_id, {expires, channels}}] ->
        if NaiveDateTime.compare(NaiveDateTime.utc_now(), expires) == :gt do
          cache_fetch(channel_id)
        else
          channels
        end
      [] ->
        cache_fetch(channel_id)
    end
  end

  def cache_fetch(channel_id) do
    case Channels.find_discord_subscriber(channel_id) do
      [] ->
        :ets.insert(:discord_relay_blocked_channels, {channel_id, NaiveDateTime.add(NaiveDateTime.utc_now(), 300)})
        []
      channels ->
        :ets.insert(:discord_relay_channels, {channel_id, {NaiveDateTime.add(NaiveDateTime.utc_now(), 300), channels}})
        channels
    end
  end
end
