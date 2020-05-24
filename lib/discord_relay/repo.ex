defmodule DiscordRelay.Repo do
  use Ecto.Repo,
    otp_app: :discord_relay,
    adapter: Ecto.Adapters.Postgres
end
