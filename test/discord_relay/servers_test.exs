defmodule DiscordRelay.ServersTest do
  use DiscordRelay.DataCase

  alias DiscordRelay.Servers

  describe "servers" do
    alias DiscordRelay.Servers.Server

    @valid_attrs %{annoucements: "some annoucements", general: "some general", guild: "some guild", key: "some key", key_id: "some key_id", name: "some name"}
    @update_attrs %{annoucements: "some updated annoucements", general: "some updated general", guild: "some updated guild", key: "some updated key", key_id: "some updated key_id", name: "some updated name"}
    @invalid_attrs %{annoucements: nil, general: nil, guild: nil, key: nil, key_id: nil, name: nil}

    def server_fixture(attrs \\ %{}) do
      {:ok, server} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Servers.create_server()

      server
    end

    test "list_servers/0 returns all servers" do
      server = server_fixture()
      assert Servers.list_servers() == [server]
    end

    test "get_server!/1 returns the server with given id" do
      server = server_fixture()
      assert Servers.get_server!(server.id) == server
    end

    test "create_server/1 with valid data creates a server" do
      assert {:ok, %Server{} = server} = Servers.create_server(@valid_attrs)
      assert server.annoucements == "some annoucements"
      assert server.general == "some general"
      assert server.guild == "some guild"
      assert server.key == "some key"
      assert server.key_id == "some key_id"
      assert server.name == "some name"
    end

    test "create_server/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Servers.create_server(@invalid_attrs)
    end

    test "update_server/2 with valid data updates the server" do
      server = server_fixture()
      assert {:ok, %Server{} = server} = Servers.update_server(server, @update_attrs)
      assert server.annoucements == "some updated annoucements"
      assert server.general == "some updated general"
      assert server.guild == "some updated guild"
      assert server.key == "some updated key"
      assert server.key_id == "some updated key_id"
      assert server.name == "some updated name"
    end

    test "update_server/2 with invalid data returns error changeset" do
      server = server_fixture()
      assert {:error, %Ecto.Changeset{}} = Servers.update_server(server, @invalid_attrs)
      assert server == Servers.get_server!(server.id)
    end

    test "delete_server/1 deletes the server" do
      server = server_fixture()
      assert {:ok, %Server{}} = Servers.delete_server(server)
      assert_raise Ecto.NoResultsError, fn -> Servers.get_server!(server.id) end
    end

    test "change_server/1 returns a server changeset" do
      server = server_fixture()
      assert %Ecto.Changeset{} = Servers.change_server(server)
    end
  end
end
