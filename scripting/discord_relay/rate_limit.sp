enum struct client_rate_limit {
    int tokens;
    Handle timer;
}

client_rate_limit client_rate_limits[MAXPLAYERS];

Action add_rate_limit_tokens(Handle timer, int client) {
    if (client_rate_limits[client].tokens < 4) {
        client_rate_limits[client].tokens++;
    }

    return Plugin_Continue;
}

void init_rate_limit(int client) {
    client_rate_limits[client].tokens = 4;
    client_rate_limits[client].timer = CreateTimer(10.0, add_rate_limit_tokens, client, TIMER_REPEAT);
}

void kill_rate_limit(int client) {
    if (client_rate_limits[client].timer != null) {
        KillTimer(client_rate_limits[client].timer);
        client_rate_limits[client].timer = null;
    }
}