defmodule DiscordRelay.Steam do
  import SweetXml

  def get_profile(steam_id) do
    case steam_id_to_steam_id64(steam_id) do
      {:ok, community_id} ->
        with {:commit, profile} <- Cachex.fetch(:steam_profile_cache, community_id, fn _ ->
          case fetch_profile(community_id) do
            {:ok, profile} ->
              {:commit, profile}
            :error -> {:ignore, :error}
          end
        end) do
          {:ok, profile}
        else
          res -> res
        end
      _ -> :error
    end
  end

  def steam_id64_to_steam_id3(community_id) do
    steam_id2 = community_id - 76_561_197_960_265_728

    if steam_id2 < 0 do
      :error
    else
      {:ok, "[U:1:#{steam_id2}]"}
    end
  end

  def steam_id_to_steam_id64(<<"STEAM_", _::binary-size(1), ":", steam_id1::binary-size(1), ":", steam_id2::binary>>) do
    {steam_id1, ""} = Integer.parse(steam_id1)
    {steam_id2, ""} = Integer.parse(steam_id2)
    {:ok, steam_id1 + steam_id2 * 2 + 76_561_197_960_265_728}
  end

  def steam_id_to_steam_id64(<<"[U:", steam_id1::binary-size(1), ":", steam_id2::binary>>) do
    {steam_id1, ""} = Integer.parse(steam_id1)
    {steam_id2, "]"} = Integer.parse(steam_id2)
    {:ok, steam_id1 + steam_id2 + 76_561_197_960_265_727}
  end

  def steam_id_to_steam_id64(<<"U:", steam_id1::binary-size(1), ":", steam_id2::binary>>) do
    steam_id_to_steam_id64("[U:#{steam_id1}:#{steam_id2}]")
  end

  def steam_id_to_steam_id64(community_id) when is_number(community_id), do: {:ok, community_id}

  def steam_id_to_steam_id64(_steam_id) do
    :error
  end

  def fetch_profile(community_id) do
    response = HTTPoison.get!("http://steamcommunity.com/profiles/#{community_id}?xml=1", [], hackney: [follow_redirect: true])

    case response do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, body}
      _resp -> :error
    end
  end

  def profile_name(steam_id) do
    case get_profile(steam_id) do
      {:ok, profile} ->
        {:ok, to_string(xpath(profile, ~x"//profile/steamID/text()"))}
      _ ->
        :error
    end
  end

  def avatar_icon(steam_id) do
    case get_profile(steam_id) do
      {:ok, profile} ->
        {:ok, to_string(xpath(profile, ~x"//profile/avatarIcon/text()"))}
      _ -> :error
    end
  end
end
