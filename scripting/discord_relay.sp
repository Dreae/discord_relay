#include <sourcemod>
#include "include/cryptosocket"

#define CHAT_SYMBOL '#'

public Plugin myinfo = {
    name = "Discord Relay",
    author = "Dreae <dreae@dreae.onl>",
    description = "Relays chat between discord and the server",
    version = "1.0.0",
    url = "https://gitlab.com/Dreae/discord_relay.git"
}

EncryptedSocket socket = null;
ConVar address_cvar = null;
ConVar key_cvar = null;
ConVar key_id_cvar = null;


public void OnPluginStart() {
    address_cvar = CreateConVar("discord_relay_address", "", "Address of the discord relay", 0, false, 0.0, false, 0.0);
    key_id_cvar = CreateConVar("discord_relay_key_id", "", "Key ID for the discord relay", 0, false, 0.0, false, 0.0);
    key_cvar = CreateConVar("discord_relay_key", "", "Key for the discord relay", FCVAR_PROTECTED | FCVAR_UNLOGGED, false, 0.0, false, 0.0);

    address_cvar.AddChangeHook(config_changed);
    key_id_cvar.AddChangeHook(config_changed);
    key_cvar.AddChangeHook(config_changed);
}

public void OnMapStart() {
    if (socket == null || !socket.Connected()) {
        reconnect_socket();
    }
}

public void config_changed(ConVar convar, const char[] old_value, const char[] new_value) {
    reconnect_socket();
}

void reconnect_socket() {
    if (socket != null) {
        socket.Close();
    }
    
    char key_id[64];
    char key[256];

    key_id_cvar.GetString(key_id, sizeof(key_id));
    key_cvar.GetString(key, sizeof(key));
    if (strlen(key) == 0 || strlen(key_id) == 0) {
        LogMessage("Discord relay key is unset, please set discord_relay_key_id and discord_relay_key");
        return;
    }

    socket = new EncryptedSocket(key_id, key, OnRelayData);

    char address[32];
    address_cvar.GetString(address, sizeof(address));
    if (strlen(address) == 0) {
        LogMessage("Discord relay address is blank, please set discord_relay_address");
        return;
    }

    char parts[2][24];
    if (ExplodeString(address, ":", parts, 2, 24, false) != 2) {
        LogError("Error parsing relay address %s", address);
        return;
    }

    socket.Connect(parts[0], StringToInt(parts[1]));
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
    if (args[0] != CHAT_SYMBOL) {
        return Plugin_Continue;
    }

    if (strcmp(command, "say", false) != 0) {
        return Plugin_Continue;
    }

    if (!IsClientAuthorized(client) || !IsClientInGame(client)) {
        return Plugin_Continue;
    }

    if (socket != INVALID_HANDLE && socket.Connected()) {
        char steam_id[32];
        GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id), true);

        char name[128];
        GetClientName(client, name, sizeof(name));

        char buffer[1028];
        strcopy(buffer, sizeof(buffer), "\xff\xff\xff\x01");

        int steam_id_size = strlen(steam_id);
        int name_size = strlen(name);
        int msg_size = strlen(args);
        
        strcopy(buffer[4], sizeof(buffer), steam_id);
        buffer[steam_id_size + 4] = '\0';

        strcopy(buffer[steam_id_size + 5], sizeof(buffer) - (steam_id_size + 6), name);
        buffer[steam_id_size + 5 + name_size] = '\0';

        strcopy(buffer[steam_id_size + name_size + 6], sizeof(buffer) - (steam_id_size + name_size + 7), args[1]);

        socket.Send(buffer, steam_id_size + name_size + msg_size + 7);

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public void OnRelayData(const char[] data, int data_size) {
    PrintToServer("Got some data %d", data_size);
}