defmodule DiscordRelay.Channels.ChannelFlag do
  @behaviour Ecto.Type
  use Bitwise

  @channel_flags %{
    admin_channel: 1 <<< 0,
    protected_channel: 1 <<< 1
  }

  def type, do: :smallint

  def equal?(a, b), do: a == b

  def cast(value) when is_list(value) do
    {:ok, value}
  end

  def cast(value) when is_number(value) do
    load(value)
  end

  def load(value) do
    flags = Enum.reduce(Map.to_list(@channel_flags), [], fn {key, flag}, flags ->
      if (value &&& flag) != 0 do
        flags ++ [key]
      else
        flags
      end
    end)

    {:ok, flags}
  end

  def dump(value) when is_list(value) do
    {:ok, Enum.reduce(value, 0, &(&2 ||| Map.get(@channel_flags, &1, 0)))}
  end

  def dump(_), do: :error
end
