defmodule DiscordRelay.Consumer do
  use Nostrum.Consumer
  alias DiscordRelay.Channels

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cached_channels = fetch_channel(msg.channel_id)
    Enum.map(cached_channels, &(DiscordRelay.ChannelManager.send_discord_message(&1.id, msg.channel_id, msg.author.username, msg.content)))
  end

  def fetch_channel(channel_id) do
    []
  end
end
