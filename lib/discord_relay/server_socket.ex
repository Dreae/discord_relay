defmodule DiscordRelay.ServerSocket do
  use CryptosocketEx.EncryptedSocket
  alias DiscordRelay.Servers
  alias DiscordRelay.Channels.ChannelFlag
  require Logger

  @s2r_server_msg 1
  @r2s_server_msg 2
  @r2s_annoucement 4
  @s2r_channel_list 5
  @r2s_channel_list 6

  def init() do
    %{server: nil}
  end

  def get_key(key_id, state) do
    case Servers.get_server_key(key_id) do
      nil -> {:error, :no_key, state}
      server ->
        DiscordRelay.ChannelManager.preload_channels(server.channels)
        DiscordRelay.ServerManager.join(server.id, self())
        Logger.info("New socket for server #{server.name}")

        {:ok, server.key, %{state | server: server}}
    end
  end

  def handle_cast({:send_server_msg, msg_data}, state) do
    %{server_name: server_name, steam_id: steam_id, user_name: user_name, msg: msg, channel: channel_id} = msg_data
    Logger.debug("Got server message through dispatch [#{server_name}] #{user_name}<#{steam_id}>: #{msg}")

    packet = <<0xff, 0xff, 0xff, @r2s_server_msg>>
      <> <<channel_id::big-unsigned-32>>
      <> server_name <> <<0>>
      <> user_name <> <<0>>
      <> msg <> <<0>>

    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:noreply, state}
  end

  def handle_cast({:send_discord_msg, msg_data}, state) do
    %{user_name: user_name, msg: msg, discord_guild_name: discord_guild_name, channel: channel_id} = msg_data
    Logger.debug("Got discord message through dispatch [#{discord_guild_name}] #{user_name}: #{msg}")

    packet = <<0xff, 0xff, 0xff, @r2s_server_msg>>
      <> <<channel_id::big-unsigned-32>>
      <> discord_guild_name <> <<0>>
      <> user_name <> <<0>>
      <> msg <> <<0>>

    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:noreply, state}
  end

  def handle_cast({:send_announcement, msg_data}, state) do
    %{user_name: user_name, msg: msg, channel: channel_id} = msg_data

    packet = <<0xff, 0xff, 0xff, @r2s_annoucement>>
      <> <<channel_id::big-unsigned-32>>
      <> user_name <> <<0>>
      <> msg <> <<0>>

    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:noreply, state}
  end

  def handle_data(<<0xff, 0xff, 0xff, @s2r_server_msg, channel_id::big-unsigned-32, data::binary>>, %{server: server} = state) do
    [steam_id, name | message] = :binary.split(data, <<0>>, [:global, :trim])
    case message do
      [message] ->
        Logger.info("Got message from [#{server.name}] on channel #{channel_id} #{name}<#{steam_id}>: #{message}")

        DiscordRelay.ChannelManager.send_server_message(channel_id, server.name, steam_id, name, message)
        {:ok, state}
      _ ->
        {:ok, state}
    end
  end

  def handle_data(<<0xff, 0xff, 0xff, @s2r_channel_list>>, %{server: server} = state) do
    packet = <<0xff, 0xff, 0xff, @r2s_channel_list, length(server.channels)::8>>

    packet = Enum.reduce(server.channels, packet, &(&2 <> <<&1.id::big-unsigned-32>> <> <<elem(ChannelFlag.dump(&1.flags), 1)::big-unsigned-16>> <> &1.name <> <<0>>))
    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:ok, state}
  end

  def handle_data(_data, state) do
    {:ok, state}
  end

  def send_server_message(pid, msg_data) do
    GenServer.cast(pid, {:send_server_msg, msg_data})
  end

  def send_discord_message(pid, msg_data) do
    GenServer.cast(pid, {:send_discord_msg, msg_data})
  end

  def send_announcement(pid, msg_data) do
    GenServer.cast(pid, {:send_announcement, msg_data})
  end
end
