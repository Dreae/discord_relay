defmodule DiscordRelay.DiscordId do
  @behaviour Ecto.Type

  def type, do: :binary

  def cast(value) when is_number(value) do
    {:ok, <<value::big-unsigned-64>>}
  end

  def cast(value) when is_binary(value) do
    __MODULE__.load(value)
  end

  def load(value) do
    <<discord_id::big-unsigned-64>> = value
    {:ok, discord_id}
  end

  def dump(value) when is_number(value) do
    __MODULE__.cast(value)
  end

  def dump(_), do: :error
end
