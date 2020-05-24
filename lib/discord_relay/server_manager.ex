defmodule DiscordRelay.ServerManager do
  use GenServer

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    {:ok, %{servers: %{}}}
  end

  def handle_cast({:new_server, {server_id, pid}}, %{servers: servers} = state) do
    Process.monitor(pid)

    if Map.has_key?(servers, server_id) do
      {:noreply, %{state | servers: Map.replace!(servers, server_id, pid)}}
    else
      {:noreply, %{state | servers: Map.put_new(servers, server_id, pid)}}
    end
  end

  def handle_cast({:send_server_message, server_id, msg_data}, %{servers: servers} = state) do
    server = servers[server_id]
    if server do
      DiscordRelay.ServerSocket.send_server_message(server, msg_data)
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{servers: servers} = state) do
    case Enum.filter(Map.to_list(servers), &(elem(&1, 1) == pid)) do
      [{server_id, _pid}] -> {:noreply, %{state | servers: Map.delete(servers, server_id)}}
      _ -> {:noreply, state}
    end
  end

  def join(server_id, pid) do
    GenServer.cast(__MODULE__, {:new_server, {server_id, pid}})
  end

  def send_server_message(server_id, msg_data) do
    GenServer.cast(__MODULE__, {:send_server_message, server_id, msg_data})
  end
end
