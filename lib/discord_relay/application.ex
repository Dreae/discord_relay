defmodule DiscordRelay.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      DiscordRelay.Repo,
      # Start the Telemetry supervisor
      DiscordRelayWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DiscordRelay.PubSub},
      # Start the Endpoint (http/https)
      DiscordRelayWeb.Endpoint,
      # Start a worker by calling: DiscordRelay.Worker.start_link(arg)
      # {DiscordRelay.Worker, arg}
      {CryptosocketEx.Agent, [DiscordRelay.ServerSocket, [address: "0.0.0.0", port: 4147]]},
      DiscordRelay.ChannelSupervisor,
      DiscordRelay.ChannelManager,
      DiscordRelay.ServerManager,
      DiscordRelay.ConsumerSupervisor,
      DiscordRelay.BanCache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DiscordRelay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DiscordRelayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
