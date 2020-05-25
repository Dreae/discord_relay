defmodule DiscordRelay.ConsumerSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    :ets.new(:discord_relay_channels, [:named_table, :public, read_concurrency: true])
    :ets.new(:discord_relay_blocked_channels, [:named_table, :public, read_concurrency: true])
    children = for n <- 1..System.schedulers_online(),
      do: Supervisor.child_spec({DiscordRelay.Consumer, []}, id: {:discord_relay, :consumer, n})

    Supervisor.init(children, strategy: :one_for_one)
  end
end
