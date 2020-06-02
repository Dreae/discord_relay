# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DiscordRelay.Repo.insert!(%DiscordRelay.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
{:ok, server} = DiscordRelay.Servers.create_server(%{name: "Test", key_id: "keyid", key: "testkey"})
{:ok, channel} = DiscordRelay.Channels.create_channel(%{name: "Test"})
{:ok, _} = DiscordRelay.Channels.create_server_subscriber(%{server_id: server.id, channel_id: channel.id})
{:ok, _} = DiscordRelay.Channels.create_discord_subscriber(%{discord_channel: 689500441167266029, channel_id: channel.id})
{:ok, _} = DiscordRelay.Channels.create_discord_subscriber(%{discord_channel: 714515026030886958, channel_id: channel.id, announcements: true})
{:ok, channel} = DiscordRelay.Channels.create_channel(%{name: "Channel 1"})
{:ok, _} = DiscordRelay.Channels.create_server_subscriber(%{server_id: server.id, channel_id: channel.id})
{:ok, _} = DiscordRelay.Channels.create_discord_subscriber(%{discord_channel: 716848340335198229, channel_id: channel.id})
{:ok, _} = DiscordRelay.Channels.create_discord_subscriber(%{discord_channel: 714515026030886958, channel_id: channel.id, announcements: true})
{:ok, channel} = DiscordRelay.Channels.create_channel(%{name: "Channel 2"})
{:ok, _} = DiscordRelay.Channels.create_server_subscriber(%{server_id: server.id, channel_id: channel.id})
{:ok, _} = DiscordRelay.Channels.create_discord_subscriber(%{discord_channel: 716848362770661407, channel_id: channel.id})
{:ok, _} = DiscordRelay.Channels.create_discord_subscriber(%{discord_channel: 714515026030886958, channel_id: channel.id, announcements: true})
