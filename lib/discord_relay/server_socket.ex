defmodule DiscordRelay.ServerSocket do
  use CryptosocketEx.EncryptedSocket
  alias DiscordRelay.Servers
  require Logger

  def init() do
    %{server: nil}
  end

  def get_key(key_id, state) do
    case Servers.get_server_key(key_id) do
      nil -> {:error, :no_key, state}
      server ->
        DiscordRelay.ChannelManager.preload_channels(server.channels)
        DiscordRelay.ServerManager.join(server.id, self())
        {:ok, server.key, %{state | server: server}}
    end
  end

  def handle_cast({:send_server_msg, msg_data}, state) do
    %{server_name: server_name, steam_id: steam_id, user_name: user_name, msg: msg} = msg_data
    Logger.debug("Got server message through dispatch [#{server_name}] #{user_name}<#{steam_id}>: #{msg}")

    packet = <<0xff, 0xff, 0xff, 2>>
      <> server_name <> <<0>>
      <> user_name <> <<0>>
      <> msg <> <<0>>

    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:noreply, state}
  end

  def handle_cast({:send_discord_msg, msg_data}, state) do
    %{user_name: user_name, msg: msg, discord_channel_id: _channel_id} = msg_data

    packet = <<0xff, 0xff, 0xff, 3>>
      <> user_name <> <<0>>
      <> msg <> <<0>>

    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:noreply, state}
  end

  def handle_cast({:send_announcement, msg_data}, state) do
    %{user_name: user_name, msg: msg, discord_channel_id: _channel_id} = msg_data

    packet = <<0xff, 0xff, 0xff, 4>>
      <> user_name <> <<0>>
      <> msg <> <<0>>

    CryptosocketEx.EncryptedSocket.send_encrypted(self(), packet)

    {:noreply, state}
  end

  def handle_data(<<0xff, 0xff, 0xff, 1, data::binary>>, %{server: server} = state) do
    [steam_id, name, message] = :binary.split(data, <<0>>, [:global, :trim])
    Logger.info("Got message from [#{server.name}] #{name}<#{steam_id}>: #{message}")

    Enum.map(server.channels, &(DiscordRelay.ChannelManager.send_server_message(&1.id, server.name, steam_id, name, message)))

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
