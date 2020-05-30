defmodule DiscordRelay.Webhooks do
  use GenServer
  alias Nostrum.Api

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_args) do
    # TODO: Use cachex
    tid = :ets.new(:discord_webhook_cache, [:named_table, :public, read_concurrency: true])

    {:ok, tid}
  end

  def handle_call(:tid, _, tid) do
    {:reply, tid, tid}
  end

  def fetch_webhook(discord_subscriber) do
    case :ets.lookup(:discord_webhook_cache, discord_subscriber.id) do
      [{_, webhook}] ->
        webhook
      _ ->
        case find_discord_webhook(discord_subscriber.id) do
          nil ->
            {:ok, new_hook} = Api.create_webhook(discord_subscriber.discord_channel, %{name: "In-Game webhook", avatar: ""}, "Send in-game messages")
            {webhook_id, ""} = Integer.parse(new_hook.id)
            {:ok, webhook} = create_discord_web_hook(%{discord_subscriber_id: discord_subscriber.id, webhook_id: webhook_id, webhook_token: new_hook.token})

            :ets.insert(:discord_webhook_cache, {discord_subscriber.id, {webhook.webhook_id, webhook.webhook_token}})

            {webhook.webhook_id, webhook.webhook_token}
          webhook ->
            :ets.insert(:discord_webhook_cache, {discord_subscriber.id, {webhook.webhook_id, webhook.webhook_token}})
            {webhook.webhook_id, webhook.webhook_token}
        end
    end
  end

  def execute_webhook(discord_subscriber, body) do
    {webhook_id, webhook_token} = fetch_webhook(discord_subscriber)
    Api.execute_webhook(webhook_id, webhook_token, body, false)
  end

  alias DiscordRelay.Webhooks.DiscordWebHook
  alias DiscordRelay.Repo
  import Ecto.Query, warn: false

  @doc """
  Returns the list of discord_hooks.

  ## Examples

      iex> list_discord_hooks()
      [%DiscordWebHook{}, ...]

  """
  def list_discord_hooks do
    Repo.all(DiscordWebHook)
  end

  @doc """
  Gets a single discord_web_hook.

  Raises `Ecto.NoResultsError` if the Discord web hook does not exist.

  ## Examples

      iex> get_discord_web_hook!(123)
      %DiscordWebHook{}

      iex> get_discord_web_hook!(456)
      ** (Ecto.NoResultsError)

  """
  def get_discord_web_hook!(id), do: Repo.get!(DiscordWebHook, id)

  @doc """
  Creates a discord_web_hook.

  ## Examples

      iex> create_discord_web_hook(%{field: value})
      {:ok, %DiscordWebHook{}}

      iex> create_discord_web_hook(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_discord_web_hook(attrs \\ %{}) do
    %DiscordWebHook{}
    |> DiscordWebHook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a discord_web_hook.

  ## Examples

      iex> update_discord_web_hook(discord_web_hook, %{field: new_value})
      {:ok, %DiscordWebHook{}}

      iex> update_discord_web_hook(discord_web_hook, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_discord_web_hook(%DiscordWebHook{} = discord_web_hook, attrs) do
    discord_web_hook
    |> DiscordWebHook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a discord_web_hook.

  ## Examples

      iex> delete_discord_web_hook(discord_web_hook)
      {:ok, %DiscordWebHook{}}

      iex> delete_discord_web_hook(discord_web_hook)
      {:error, %Ecto.Changeset{}}

  """
  def delete_discord_web_hook(%DiscordWebHook{} = discord_web_hook) do
    Repo.delete(discord_web_hook)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking discord_web_hook changes.

  ## Examples

      iex> change_discord_web_hook(discord_web_hook)
      %Ecto.Changeset{data: %DiscordWebHook{}}

  """
  def change_discord_web_hook(%DiscordWebHook{} = discord_web_hook, attrs \\ %{}) do
    DiscordWebHook.changeset(discord_web_hook, attrs)
  end

  def find_discord_webhook(subscriber_id) do
    Repo.one(from w in DiscordWebHook, where: w.discord_subscriber_id == ^subscriber_id)
  end
end
