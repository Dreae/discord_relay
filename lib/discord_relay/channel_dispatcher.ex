defmodule DiscordRelay.ChannelDispatcher do
  use GenServer

  def start_link(channel) do
    GenServer.start_link(__MODULE__, channel)
  end

  def init([%{servers: servers, discord_subscribers: discord_channels} = _channel]) do
    {:ok, %{servers: servers, discord_channels: discord_channels}}
  end

  def handle_info({:new_server_message, msg_data}, %{servers: servers, discord_channels: discord_channels} = state) do
    Enum.map(servers, &(DiscordRelay.ServerManager.send_server_message(&1.id, msg_data)))

    %{server_name: server_name, user_name: user_name, steam_id: steam_id, msg: msg} = msg_data
    Enum.map(discord_channels, fn (channel) ->
      Nostrum.Api.create_message(channel.discord_channel, "[#{server_name}] #{user_name}<#{steam_id}>: #{msg}")
    end)

    {:noreply, state}
  end

  def handle_info({:new_discord_message, msg_data}, %{servers: _servers} = state) do
    %{user_name: _user_name, msg: _msg, channel_id: _discord_channel_id} = msg_data

    {:noreply, state}
  end

  def send_server_message(channel, message) do
    send channel, {:new_server_message, message}
  end

  def send_discord_message(channel, message) do
    send channel, {:new_discord_message, message}
  end
end
