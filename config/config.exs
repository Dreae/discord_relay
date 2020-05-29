# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :discord_relay,
  ecto_repos: [DiscordRelay.Repo]

# Configures the endpoint
config :discord_relay, DiscordRelayWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Kzz5Abfgj/XPVeFDYBxYVKmveZ8EJihgO56fUiINerS6naqkuMjcX5PCPpliBHBS",
  render_errors: [view: DiscordRelayWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DiscordRelay.PubSub,
  live_view: [signing_salt: "7u3K7E6c"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :nosedrum, prefix: "!"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
