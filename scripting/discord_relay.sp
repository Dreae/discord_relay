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
    if (data_size < 4) {
        return;
    }

    if (data[0] == '\xff' && data[1] == '\xff' && data[2] == '\xff') {
        if (data[3] == '\x02') {
            print_server_msg(data[4], data_size - 4);
        } else if (data[3] == '\x03') {
            print_discord_msg(data[4], data_size - 4);
        } else if (data[3] == '\x04') {
            print_announcement(data[4], data_size - 4);
        }
    }
}

void c_print_to_chat_all(const char[] msg, any ...) {
    char buffer[1024];
    VFormat(buffer, sizeof(buffer), msg, 2);

    UserMsg id = GetUserMessageId("SayText2");
    if (id == INVALID_MESSAGE_ID) {
        PrintToChatAll(buffer);
    } else {
        Handle usr_msg = StartMessageAll("SayText2", USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
        if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
            PbSetInt(usr_msg, "ent_idx", 0);
            PbSetInt(usr_msg, "chat", true);
            PbSetString(usr_msg, "msg_name", buffer);
            PbAddString(usr_msg, "params", "");
            PbAddString(usr_msg, "params", "");
            PbAddString(usr_msg, "params", "");
            PbAddString(usr_msg, "params", "");
        } else {
            BfWriteByte(usr_msg, 0); // Message author
            BfWriteByte(usr_msg, true); // Chat message
            BfWriteString(usr_msg, buffer); // Message text
        }
        EndMessage();
    }
}

void print_server_msg(const char[] data, int data_size) {
    char buffers[3][1024];
    explode_binary(data, data_size, buffers, 3, 1024);
    
    c_print_to_chat_all("\x07f1faee[%s] \x071d3557%s: \x07a8dadc%s", buffers[0], buffers[1], buffers[2])
}

void print_discord_msg(const char[] data, int data_size) {
    char buffers[2][1024];
    explode_binary(data, data_size, buffers, 2, 1024);

    c_print_to_chat_all("\x07f1faee[Discord] \x071d3557%s: \x07a8dadc%s", buffers[0], buffers[1]);
}

void print_announcement(const char[] data, int data_size) {
    char buffers[2][1024];
    explode_binary(data, data_size, buffers, 2, 1024);

    c_print_to_chat_all("\x07e63946[Annoucement] \x071d3557%s: \x07a8dadc%s", buffers[0], buffers[1]);
}

int explode_binary(const char[] data, int data_size, char[][] buffers, int num_buffers, int buffer_size) {
    int buffer = 0;
    int i = 0;
    for (int c = 0; c < data_size; c++) {
        if (data[c] == '\0') {
            buffer++;
            i = 0;
            if (buffer > num_buffers) {
                break;
            }
        } else {
            if (i > buffer_size) {
                continue;
            }
            
            buffers[buffer][i] = data[c]
            i++;
        }
    }
}