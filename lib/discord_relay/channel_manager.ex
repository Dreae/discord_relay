defmodule DiscordRelay.ChannelManager do
  use GenServer
  alias DiscordRelay.Channels
  alias DiscordRelay.ChannelSupervisor
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{channels: %{}}}
  end

  def handle_continue({:preload_channels, [channel | remaining]}, %{channels: channels} = state) do
    if Map.has_key?(channels, channel.id) do
      {:noreply, state, {:continue, {:preload_channels, remaining}}}
    else
      Logger.debug("Preloading #{channel.id}")
      channel = Channels.get_full_channel(channel.id)
      {:ok, pid} = ChannelSupervisor.start_child(channel)

      {:noreply, %{state | channels: Map.put_new(channels, channel.id, pid)}, {:continue, {:preload_channels, remaining}}}
    end
  end

  def handle_continue({:preload_channels, []}, state) do
    {:noreply, state}
  end

  def handle_cast({:preload_channels, channels}, state) do
    {:noreply, state, {:continue, {:preload_channels, channels}}}
  end

  def handle_cast({:send_server_msg, channel_id, message}, %{channels: channels} = state) do
    channel = channels[channel_id]
    if channel do
      DiscordRelay.ChannelDispatcher.send_server_message(channel, message)
    end

    {:noreply, state}
  end

  def handle_cast({:send_discord_msg, channel_id, message}, %{channels: channels} = state) do
    channel = channels[channel_id]
    if channel do
      DiscordRelay.ChannelDispatcher.send_discord_message(channel, message)
    end

    {:noreply, state}
  end

  def preload_channels(channels) do
    GenServer.cast(__MODULE__, {:preload_channels, channels})
  end

  def send_server_message(channel_id, server_name, steam_id, user_name, msg) do
    Logger.debug("Sending server message to #{channel_id}")
    GenServer.cast(__MODULE__, {:send_server_msg, channel_id, %{server_name: server_name, steam_id: steam_id, user_name: user_name, msg: msg}})
  end

  def send_discord_message(channel_id, discord_channel_id, user_name, msg) do
    GenServer.cast(__MODULE__, {:send_discord_msg, channel_id, %{discord_channel_id: discord_channel_id, user_name: user_name, msg: msg}})
  end
end
