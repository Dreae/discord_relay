defmodule DiscordRelay.Steam do
  import SweetXml

  def steam_id64_to_steam_id3(community_id) do
    unless rem(community_id, 2) == 1 do
      raise "SteamID3 only supports public universe"
    end

    steam_id2 = community_id - 76_561_197_960_265_728

    unless steam_id2 > 0 do
      raise "SteamID #{community_id} is too small."
    end

    "[U:1:#{steam_id2}]"
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

  def steam_id_to_steam_id64(_steam_id) do
    :error
  end

  def fetch_profile_name(community_id) do
    response = HTTPoison.get!("http://steamcommunity.com/profiles/#{community_id}?xml=1", [], hackney: [follow_redirect: true])

    case response do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, xpath(body, ~x"//profile/steamID/text()")}
      _resp -> :error
    end
  end
end
