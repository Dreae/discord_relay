defmodule DiscordRelay.ChannelsTest do
  use DiscordRelay.DataCase

  alias DiscordRelay.Channels

  describe "channels" do
    alias DiscordRelay.Channels.Channel

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def channel_fixture(attrs \\ %{}) do
      {:ok, channel} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Channels.create_channel()

      channel
    end

    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      assert Channels.list_channels() == [channel]
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Channels.get_channel!(channel.id) == channel
    end

    test "create_channel/1 with valid data creates a channel" do
      assert {:ok, %Channel{} = channel} = Channels.create_channel(@valid_attrs)
      assert channel.name == "some name"
    end

    test "create_channel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Channels.create_channel(@invalid_attrs)
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{} = channel} = Channels.update_channel(channel, @update_attrs)
      assert channel.name == "some updated name"
    end

    test "update_channel/2 with invalid data returns error changeset" do
      channel = channel_fixture()
      assert {:error, %Ecto.Changeset{}} = Channels.update_channel(channel, @invalid_attrs)
      assert channel == Channels.get_channel!(channel.id)
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{}} = Channels.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Channels.get_channel!(channel.id) end
    end

    test "change_channel/1 returns a channel changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Channels.change_channel(channel)
    end
  end

  describe "discord_subscribers" do
    alias DiscordRelay.Channels.DiscordSubscriber

    @valid_attrs %{announcements: true, channel_id: "some channel_id"}
    @update_attrs %{announcements: false, channel_id: "some updated channel_id"}
    @invalid_attrs %{announcements: nil, channel_id: nil}

    def discord_subscriber_fixture(attrs \\ %{}) do
      {:ok, discord_subscriber} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Channels.create_discord_subscriber()

      discord_subscriber
    end

    test "list_discord_subscribers/0 returns all discord_subscribers" do
      discord_subscriber = discord_subscriber_fixture()
      assert Channels.list_discord_subscribers() == [discord_subscriber]
    end

    test "get_discord_subscriber!/1 returns the discord_subscriber with given id" do
      discord_subscriber = discord_subscriber_fixture()
      assert Channels.get_discord_subscriber!(discord_subscriber.id) == discord_subscriber
    end

    test "create_discord_subscriber/1 with valid data creates a discord_subscriber" do
      assert {:ok, %DiscordSubscriber{} = discord_subscriber} = Channels.create_discord_subscriber(@valid_attrs)
      assert discord_subscriber.announcements == true
      assert discord_subscriber.channel_id == "some channel_id"
    end

    test "create_discord_subscriber/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Channels.create_discord_subscriber(@invalid_attrs)
    end

    test "update_discord_subscriber/2 with valid data updates the discord_subscriber" do
      discord_subscriber = discord_subscriber_fixture()
      assert {:ok, %DiscordSubscriber{} = discord_subscriber} = Channels.update_discord_subscriber(discord_subscriber, @update_attrs)
      assert discord_subscriber.announcements == false
      assert discord_subscriber.channel_id == "some updated channel_id"
    end

    test "update_discord_subscriber/2 with invalid data returns error changeset" do
      discord_subscriber = discord_subscriber_fixture()
      assert {:error, %Ecto.Changeset{}} = Channels.update_discord_subscriber(discord_subscriber, @invalid_attrs)
      assert discord_subscriber == Channels.get_discord_subscriber!(discord_subscriber.id)
    end

    test "delete_discord_subscriber/1 deletes the discord_subscriber" do
      discord_subscriber = discord_subscriber_fixture()
      assert {:ok, %DiscordSubscriber{}} = Channels.delete_discord_subscriber(discord_subscriber)
      assert_raise Ecto.NoResultsError, fn -> Channels.get_discord_subscriber!(discord_subscriber.id) end
    end

    test "change_discord_subscriber/1 returns a discord_subscriber changeset" do
      discord_subscriber = discord_subscriber_fixture()
      assert %Ecto.Changeset{} = Channels.change_discord_subscriber(discord_subscriber)
    end
  end

  describe "server_subscribers" do
    alias DiscordRelay.Channels.ServerSubscriber

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def server_subscriber_fixture(attrs \\ %{}) do
      {:ok, server_subscriber} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Channels.create_server_subscriber()

      server_subscriber
    end

    test "list_server_subscribers/0 returns all server_subscribers" do
      server_subscriber = server_subscriber_fixture()
      assert Channels.list_server_subscribers() == [server_subscriber]
    end

    test "get_server_subscriber!/1 returns the server_subscriber with given id" do
      server_subscriber = server_subscriber_fixture()
      assert Channels.get_server_subscriber!(server_subscriber.id) == server_subscriber
    end

    test "create_server_subscriber/1 with valid data creates a server_subscriber" do
      assert {:ok, %ServerSubscriber{} = server_subscriber} = Channels.create_server_subscriber(@valid_attrs)
    end

    test "create_server_subscriber/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Channels.create_server_subscriber(@invalid_attrs)
    end

    test "update_server_subscriber/2 with valid data updates the server_subscriber" do
      server_subscriber = server_subscriber_fixture()
      assert {:ok, %ServerSubscriber{} = server_subscriber} = Channels.update_server_subscriber(server_subscriber, @update_attrs)
    end

    test "update_server_subscriber/2 with invalid data returns error changeset" do
      server_subscriber = server_subscriber_fixture()
      assert {:error, %Ecto.Changeset{}} = Channels.update_server_subscriber(server_subscriber, @invalid_attrs)
      assert server_subscriber == Channels.get_server_subscriber!(server_subscriber.id)
    end

    test "delete_server_subscriber/1 deletes the server_subscriber" do
      server_subscriber = server_subscriber_fixture()
      assert {:ok, %ServerSubscriber{}} = Channels.delete_server_subscriber(server_subscriber)
      assert_raise Ecto.NoResultsError, fn -> Channels.get_server_subscriber!(server_subscriber.id) end
    end

    test "change_server_subscriber/1 returns a server_subscriber changeset" do
      server_subscriber = server_subscriber_fixture()
      assert %Ecto.Changeset{} = Channels.change_server_subscriber(server_subscriber)
    end
  end

  describe "discord_hooks" do
    alias DiscordRelay.Channels.DiscordWebHook

    @valid_attrs %{guild_id: "some guild_id", webhook_id: "some webhook_id", webhook_token: ~N[2010-04-17 14:00:00]}
    @update_attrs %{guild_id: "some updated guild_id", webhook_id: "some updated webhook_id", webhook_token: ~N[2011-05-18 15:01:01]}
    @invalid_attrs %{guild_id: nil, webhook_id: nil, webhook_token: nil}

    def discord_web_hook_fixture(attrs \\ %{}) do
      {:ok, discord_web_hook} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Channels.create_discord_web_hook()

      discord_web_hook
    end

    test "list_discord_hooks/0 returns all discord_hooks" do
      discord_web_hook = discord_web_hook_fixture()
      assert Channels.list_discord_hooks() == [discord_web_hook]
    end

    test "get_discord_web_hook!/1 returns the discord_web_hook with given id" do
      discord_web_hook = discord_web_hook_fixture()
      assert Channels.get_discord_web_hook!(discord_web_hook.id) == discord_web_hook
    end

    test "create_discord_web_hook/1 with valid data creates a discord_web_hook" do
      assert {:ok, %DiscordWebHook{} = discord_web_hook} = Channels.create_discord_web_hook(@valid_attrs)
      assert discord_web_hook.guild_id == "some guild_id"
      assert discord_web_hook.webhook_id == "some webhook_id"
      assert discord_web_hook.webhook_token == ~N[2010-04-17 14:00:00]
    end

    test "create_discord_web_hook/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Channels.create_discord_web_hook(@invalid_attrs)
    end

    test "update_discord_web_hook/2 with valid data updates the discord_web_hook" do
      discord_web_hook = discord_web_hook_fixture()
      assert {:ok, %DiscordWebHook{} = discord_web_hook} = Channels.update_discord_web_hook(discord_web_hook, @update_attrs)
      assert discord_web_hook.guild_id == "some updated guild_id"
      assert discord_web_hook.webhook_id == "some updated webhook_id"
      assert discord_web_hook.webhook_token == ~N[2011-05-18 15:01:01]
    end

    test "update_discord_web_hook/2 with invalid data returns error changeset" do
      discord_web_hook = discord_web_hook_fixture()
      assert {:error, %Ecto.Changeset{}} = Channels.update_discord_web_hook(discord_web_hook, @invalid_attrs)
      assert discord_web_hook == Channels.get_discord_web_hook!(discord_web_hook.id)
    end

    test "delete_discord_web_hook/1 deletes the discord_web_hook" do
      discord_web_hook = discord_web_hook_fixture()
      assert {:ok, %DiscordWebHook{}} = Channels.delete_discord_web_hook(discord_web_hook)
      assert_raise Ecto.NoResultsError, fn -> Channels.get_discord_web_hook!(discord_web_hook.id) end
    end

    test "change_discord_web_hook/1 returns a discord_web_hook changeset" do
      discord_web_hook = discord_web_hook_fixture()
      assert %Ecto.Changeset{} = Channels.change_discord_web_hook(discord_web_hook)
    end
  end
end
