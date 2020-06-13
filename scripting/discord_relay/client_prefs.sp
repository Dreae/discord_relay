
Cookie listening_channel_cookie;
Cookie admin_channel_cookie;

void init_client_settings() {
    for (int c = 1; c <= MaxClients; c++) {
        if (IsClientConnected(c)) {
            if (AreClientCookiesCached(c)) {
                OnClientCookiesCached(c);
            }

            OnClientConnected(c);
        }
    }
}

void load_client_prefs(int client) {
    if (listening_channel_cookie.GetClientTime(client) == 0) {
        int default_channel_id = default_channel_cvar.IntValue;
        if (default_channel_id == 0) {
            default_channel_id = 0xffffffff
        }

        char channel_buffer[12];
        IntToString(default_channel_id, channel_buffer, sizeof(channel_buffer));
        listening_channel_cookie.Set(client, channel_buffer);
        client_channel_id[client] = default_channel_id;
    } else {
        char channel_buffer[12];
        listening_channel_cookie.Get(client, channel_buffer, sizeof(channel_buffer));
        client_channel_id[client] = StringToInt(channel_buffer);
    }

    if (admin_channel_cookie.GetClientTime(client) == 0) {
        int default_channel_id = default_admin_channel_cvar.IntValue;

        char channel_buffer[12];
        IntToString(default_channel_id, channel_buffer, sizeof(channel_buffer));
        admin_channel_cookie.Set(client, channel_buffer);
        client_admin_channel_id[client] = default_channel_id;
    } else {
        char channel_buffer[12];
        admin_channel_cookie.Get(client, channel_buffer, sizeof(channel_buffer));
        client_admin_channel_id[client] = StringToInt(channel_buffer);
    }
}