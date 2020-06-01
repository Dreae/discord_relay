defmodule DiscordRelayWeb.PageController do
  use DiscordRelayWeb, :controller
  alias DiscordRelay.Channels
  alias DiscordRelay.Bans

  def index(conn, _params) do
    channels = Channels.list_channels()
    bans = Bans.list_bans();

    render(conn, "index.html", %{channels: channels, bans: bans})
  end
end
