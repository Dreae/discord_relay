defmodule DiscordRelay.Channels do
  @moduledoc """
  The Channels context.
  """

  import Ecto.Query, warn: false
  alias DiscordRelay.Repo

  alias DiscordRelay.Channels.Channel

  @doc """
  Returns the list of channels.

  ## Examples

      iex> list_channels()
      [%Channel{}, ...]

  """
  def list_channels do
    Repo.all(Channel)
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id), do: Repo.get!(Channel, id)

  @doc """
  Creates a channel.

  ## Examples

      iex> create_channel(%{field: value})
      {:ok, %Channel{}}

      iex> create_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(channel, %{field: new_value})
      {:ok, %Channel{}}

      iex> update_channel(channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a channel.

  ## Examples

      iex> delete_channel(channel)
      {:ok, %Channel{}}

      iex> delete_channel(channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  def get_full_channel(channel_id) do
    Repo.one(from c in Channel, where: c.id == ^channel_id, preload: [:servers, :discord_subscribers])
  end

  alias DiscordRelay.Channels.DiscordSubscriber

  @doc """
  Returns the list of discord_subscribers.

  ## Examples

      iex> list_discord_subscribers()
      [%DiscordSubscriber{}, ...]

  """
  def list_discord_subscribers do
    Repo.all(DiscordSubscriber)
  end

  @doc """
  Gets a single discord_subscriber.

  Raises `Ecto.NoResultsError` if the Discord subscriber does not exist.

  ## Examples

      iex> get_discord_subscriber!(123)
      %DiscordSubscriber{}

      iex> get_discord_subscriber!(456)
      ** (Ecto.NoResultsError)

  """
  def get_discord_subscriber!(id), do: Repo.get!(DiscordSubscriber, id)

  @doc """
  Creates a discord_subscriber.

  ## Examples

      iex> create_discord_subscriber(%{field: value})
      {:ok, %DiscordSubscriber{}}

      iex> create_discord_subscriber(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_discord_subscriber(attrs \\ %{}) do
    %DiscordSubscriber{}
    |> DiscordSubscriber.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a discord_subscriber.

  ## Examples

      iex> update_discord_subscriber(discord_subscriber, %{field: new_value})
      {:ok, %DiscordSubscriber{}}

      iex> update_discord_subscriber(discord_subscriber, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_discord_subscriber(%DiscordSubscriber{} = discord_subscriber, attrs) do
    discord_subscriber
    |> DiscordSubscriber.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a discord_subscriber.

  ## Examples

      iex> delete_discord_subscriber(discord_subscriber)
      {:ok, %DiscordSubscriber{}}

      iex> delete_discord_subscriber(discord_subscriber)
      {:error, %Ecto.Changeset{}}

  """
  def delete_discord_subscriber(%DiscordSubscriber{} = discord_subscriber) do
    Repo.delete(discord_subscriber)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking discord_subscriber changes.

  ## Examples

      iex> change_discord_subscriber(discord_subscriber)
      %Ecto.Changeset{data: %DiscordSubscriber{}}

  """
  def change_discord_subscriber(%DiscordSubscriber{} = discord_subscriber, attrs \\ %{}) do
    DiscordSubscriber.changeset(discord_subscriber, attrs)
  end

  alias DiscordRelay.Channels.ServerSubscriber

  @doc """
  Returns the list of server_subscribers.

  ## Examples

      iex> list_server_subscribers()
      [%ServerSubscriber{}, ...]

  """
  def list_server_subscribers do
    Repo.all(ServerSubscriber)
  end

  @doc """
  Gets a single server_subscriber.

  Raises `Ecto.NoResultsError` if the Server subscriber does not exist.

  ## Examples

      iex> get_server_subscriber!(123)
      %ServerSubscriber{}

      iex> get_server_subscriber!(456)
      ** (Ecto.NoResultsError)

  """
  def get_server_subscriber!(id), do: Repo.get!(ServerSubscriber, id)

  @doc """
  Creates a server_subscriber.

  ## Examples

      iex> create_server_subscriber(%{field: value})
      {:ok, %ServerSubscriber{}}

      iex> create_server_subscriber(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_server_subscriber(attrs \\ %{}) do
    %ServerSubscriber{}
    |> ServerSubscriber.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a server_subscriber.

  ## Examples

      iex> update_server_subscriber(server_subscriber, %{field: new_value})
      {:ok, %ServerSubscriber{}}

      iex> update_server_subscriber(server_subscriber, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_server_subscriber(%ServerSubscriber{} = server_subscriber, attrs) do
    server_subscriber
    |> ServerSubscriber.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a server_subscriber.

  ## Examples

      iex> delete_server_subscriber(server_subscriber)
      {:ok, %ServerSubscriber{}}

      iex> delete_server_subscriber(server_subscriber)
      {:error, %Ecto.Changeset{}}

  """
  def delete_server_subscriber(%ServerSubscriber{} = server_subscriber) do
    Repo.delete(server_subscriber)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking server_subscriber changes.

  ## Examples

      iex> change_server_subscriber(server_subscriber)
      %Ecto.Changeset{data: %ServerSubscriber{}}

  """
  def change_server_subscriber(%ServerSubscriber{} = server_subscriber, attrs \\ %{}) do
    ServerSubscriber.changeset(server_subscriber, attrs)
  end
end
