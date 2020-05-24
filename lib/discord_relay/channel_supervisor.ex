defmodule DiscordRelay.ChannelSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(channel) do
    child_spec = {DiscordRelay.ChannelDispatcher, [channel]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
