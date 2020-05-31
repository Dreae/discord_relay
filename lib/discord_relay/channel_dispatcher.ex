defmodule DiscordRelay.ChannelDispatcher do
  use GenServer
  alias DiscordRelay.Channels
  alias DiscordRelay.ChannelManager
  alias DiscordRelay.BanCache
  alias DiscordRelay.Webhooks
  alias DiscordRelay.Steam

  require Logger

  def start_link(channel) do
    GenServer.start_link(__MODULE__, channel)
  end

  def init(%{servers: servers, discord_subscribers: discord_channels, id: id} = _channel) do
    Logger.debug("Starting dispatcher for channel #{id}")
    :timer.send_interval(300_000, :refresh_channel)

    ChannelManager.join(self(), id)
    {:ok, %{servers: servers, discord_channels: discord_channels, channel_id: id}}
  end

  def handle_info({:new_server_message, msg_data}, %{servers: servers, discord_channels: discord_channels} = state) do
    %{server_name: _server_name, user_name: user_name, steam_id: steam_id, msg: msg} = msg_data
    unless BanCache.is_banned(steam_id) do
      Enum.map(servers, &(DiscordRelay.ServerManager.send_server_message(&1.id, msg_data)))

      Enum.map(discord_channels, fn (channel) ->
        unless channel.announcements do
          avatar_url = case Steam.avatar_icon(steam_id) do
            {:ok, url} -> url
            _ -> nil
          end

          Webhooks.execute_webhook(channel, %{content: "#{sanitize_msg(msg)}", username: "#{user_name} #{steam_id}", avatar_url: avatar_url, allowed_mentions: %{parse: []}})
        end
      end)
    end

    {:noreply, state}
  end

  def handle_info({:new_discord_message, msg_data}, %{servers: servers} = state) do
    Enum.map(servers, &(DiscordRelay.ServerManager.send_discord_message(&1.id, msg_data)))

    {:noreply, state}
  end

  def handle_info({:new_announcement, msg_data}, %{servers: servers} = state) do
    Enum.map(servers, &(DiscordRelay.ServerManager.send_announcement(&1.id, msg_data)))

    {:noreply, state}
  end

  def handle_info(:refresh_channel, %{channel_id: id} = state) do
    channel = Channels.get_full_channel(id)

    {:noreply, %{state | servers: channel.servers, discord_channels: channel.discord_subscribers}}
  end

  def sanitize_msg(msg) do
    String.replace(msg, ["[", "]", "(", ")", "*", "#", "?", "@", "_", "-"], fn <<char>> -> <<"\\", char>> end)
  end

  def send_server_message(channel, message) do
    send channel, {:new_server_message, message}
  end

  def send_discord_message(channel, message) do
    send channel, {:new_discord_message, message}
  end

  def send_annoucement(channel, message) do
    send channel, {:new_announcement, message}
  end
end
