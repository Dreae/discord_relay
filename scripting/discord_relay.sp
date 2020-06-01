#include <sourcemod>
#include <clientprefs>
#include "include/cryptosocket"

#define CHAT_SYMBOL '#'

public Plugin myinfo = {
    name = "Discord Relay",
    author = "Dreae <dreae@dreae.onl>",
    description = "Relays chat between discord and the server",
    version = "1.0.2",
    url = "https://gitlab.com/Dreae/discord_relay.git"
}

enum struct channel {
    int channel_id;
    char channel_name[255];
}

channel server_channels[256];

EncryptedSocket socket = null;
ConVar address_cvar = null;
ConVar key_cvar = null;
ConVar key_id_cvar = null;
ConVar advert_cvar = null;
ConVar default_channel_cvar = null;
Handle advert_timer = null;
float connection_attempt = 0.0;
Cookie listening_channel_cookie;


public void OnPluginStart() {
    address_cvar = CreateConVar("discord_relay_address", "", "Address of the discord relay", 0, false, 0.0, false, 0.0);
    key_id_cvar = CreateConVar("discord_relay_key_id", "", "Key ID for the discord relay", 0, false, 0.0, false, 0.0);
    key_cvar = CreateConVar("discord_relay_key", "", "Key for the discord relay", FCVAR_PROTECTED | FCVAR_UNLOGGED, false, 0.0, false, 0.0);
    advert_cvar = CreateConVar("discord_relay_adverts", "1", "Enable discord relaya dverts", 0, false, 0.0, false, 0.0);
    default_channel_cvar = CreateConVar("discord_relay_default_channel", "0", "Default channel clients listen to", 0, false, 0.0, false, 0.0);

    RegServerCmd("discord_relay_list_channels", cmd_list_channels, "List channels this server is listening to", 0);
    listening_channel_cookie = new Cookie("discord_listening_channel", "The channel this client is listening to", CookieAccess_Protected);

    address_cvar.AddChangeHook(config_changed);
    key_id_cvar.AddChangeHook(config_changed);
    key_cvar.AddChangeHook(config_changed);
    advert_cvar.AddChangeHook(advert_cvar_changed);
}

public void OnMapStart() {
    request_channels();
    start_reconnect();
}

public Action cmd_list_channels(int args) {
    int c = 0;
    while(server_channels[c].channel_id != 0) {
        PrintToServer("%d - %s", server_channels[c].channel_id, server_channels[c].channel_name);
        c++;
    }
    request_channels();
}

public void OnConfigsExecuted() {
    if (advert_cvar.BoolValue) {
        if (advert_timer == null) {
            advert_timer = CreateTimer(120.0, print_advert, _, TIMER_REPEAT);
        }
    }
}

public void OnClientCookiesCached(int client) {
    if (listening_channel_cookie.GetClientTime(client) == 0) {
        int default_channel_id = default_channel_cvar.IntValue;
        if (default_channel_id == 0) {
            default_channel_id = 0xffffffff
        }

        char channel_buffer[12];
        IntToString(default_channel_id, channel_buffer, sizeof(channel_buffer));
        listening_channel_cookie.Set(client, channel_buffer);
    }
}

public void config_changed(ConVar convar, const char[] old_value, const char[] new_value) {
    start_reconnect();
}

public void advert_cvar_changed(ConVar convar, const char[] old_value, const char[] new_value) {
    if (advert_cvar.BoolValue) {
        print_advert(null);
        if (advert_timer == null) {
            advert_timer = CreateTimer(120.0, print_advert, _, TIMER_REPEAT);
        }
    } else {
        if (advert_timer != null) {
            KillTimer(advert_timer);
            advert_timer = null;
        }
    }
}

Action print_advert(Handle timer) {
    if (socket.Connected()) {
        c_print_to_chat_all("\x07f1faee[Discord] \x07a8dadcThis server is connected to discord. Put a \x07e63946# \x07a8dadcin front of your message to chat with discord.");\
    }
    return Plugin_Continue;
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
        return;
    }

    socket = new EncryptedSocket(key_id, key, OnRelayData);

    char address[32];
    address_cvar.GetString(address, sizeof(address));
    if (strlen(address) == 0) {
        return;
    }

    char parts[2][24];
    if (ExplodeString(address, ":", parts, 2, 24, false) != 2) {
        LogError("Error parsing relay address %s", address);
        return;
    }

    socket.Connect(parts[0], StringToInt(parts[1]), on_connected);
    socket.OnDisconnected(on_disconnected);
}

void start_reconnect() {
    if (socket == null || !socket.Connected()) {
        CreateTimer(Pow(2.0, connection_attempt) - 1.0, reconnect_timer, _, TIMER_FLAG_NO_MAPCHANGE);
        if (connection_attempt < 6.0) {
            connection_attempt = connection_attempt + 1.0;
        }
    }
}

public void on_connected(EncryptedSocket _socket) {
    request_channels();
}

public void on_disconnected(EncryptedSocket _socket) {
    start_reconnect();
}

public Action reconnect_timer(Handle timer) {
    if (socket == null || !socket.Connected()) {
        reconnect_socket();
        start_reconnect();
    } else {
        connection_attempt = 0.0;
    }
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
    if (args[0] != CHAT_SYMBOL) {
        return Plugin_Continue;
    }

    if (strcmp(command, "say", false) != 0) {
        return Plugin_Continue;
    }

    if (!IsClientAuthorized(client) || !IsClientInGame(client) || !AreClientCookiesCached(client)) {
        return Plugin_Continue;
    }

    if (socket != INVALID_HANDLE && socket.Connected()) {
        char channel_buffer[12];
        listening_channel_cookie.Get(client, channel_buffer, sizeof(channel_buffer));
        int channel_id = StringToInt(channel_buffer);
        if (channel_id == 0xffffffff) {
            int clients[1];
            clients[0] = client;
            c_print_to_chat(clients, 1, "\x07f1faee[Discord] \x07a8dadcYou cannot broadcast to all channels.")
            return Plugin_Stop;
        }

        char steam_id[32];
        GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id), true);

        char name[128];
        GetClientName(client, name, sizeof(name));

        char buffer[1028];
        strcopy(buffer, sizeof(buffer), "\xff\xff\xff\x01");
        add_channel_id(channel_id, buffer);

        int steam_id_size = strlen(steam_id);
        int name_size = strlen(name);
        int msg_size = strlen(args);
        
        strcopy(buffer[8], sizeof(buffer), steam_id);
        buffer[steam_id_size + 8] = '\0';

        strcopy(buffer[steam_id_size + 9], sizeof(buffer) - (steam_id_size + 10), name);
        buffer[steam_id_size + 9 + name_size] = '\0';

        strcopy(buffer[steam_id_size + name_size + 10], sizeof(buffer) - (steam_id_size + name_size + 11), args[1]);

        socket.Send(buffer, steam_id_size + name_size + msg_size + 11);

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void add_channel_id(int channel_id, char[] buffer) {
    buffer[0] = (channel_id >> 24) & 0xff;
    buffer[0] = (channel_id >> 16) & 0xff;
    buffer[0] = (channel_id >> 8) & 0xff;
    buffer[0] = channel_id & 0xff;
}

void request_channels() {
    if (socket != null && socket.Connected()) {
        socket.Send("\xff\xff\xff\x05", 4);
    }
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
        } else if (data[3] == '\x06') {
            parse_server_channels(data[4], data_size - 5);
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

void c_print_to_chat(int[] clients, int num_clients, const char[] msg) {
    UserMsg id = GetUserMessageId("SayText2");
    if (id == INVALID_MESSAGE_ID) {
        for (int client = 0; client < num_clients; client++) {
            PrintToChat(clients[client], msg);
        }
    } else {
        Handle usr_msg = StartMessage("SayText2", clients, num_clients, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
        if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
            PbSetInt(usr_msg, "ent_idx", 0);
            PbSetInt(usr_msg, "chat", true);
            PbSetString(usr_msg, "msg_name", msg);
            PbAddString(usr_msg, "params", "");
            PbAddString(usr_msg, "params", "");
            PbAddString(usr_msg, "params", "");
            PbAddString(usr_msg, "params", "");
        } else {
            BfWriteByte(usr_msg, 0); // Message author
            BfWriteByte(usr_msg, true); // Chat message
            BfWriteString(usr_msg, msg); // Message text
        }
        EndMessage();
    }
}

void print_to_channel(int channel_id, const char[] msg, any ...) {
    char buffer[1024];
    VFormat(buffer, sizeof(buffer), msg, 3);
    int[] clients = new int[MaxClients];
    int num_clients = 0;

    for (int client = 1; client <= MaxClients; client++) {
        if (!AreClientCookiesCached(client)) {
            continue;
        }

        char channel_buffer[12];
        listening_channel_cookie.Get(client, channel_buffer, sizeof(channel_buffer));
        int client_channel = StringToInt(channel_buffer);
        if (client_channel == channel_id || client_channel == 0xffffffff) {
            clients[num_clients] = client;
            num_clients++;
        }
    }

    c_print_to_chat(clients, num_clients, buffer);
}

void print_server_msg(const char[] data, int data_size) {
    char buffers[3][1024];
    int channel_id = read_channel_id(data);

    explode_binary(data[4], data_size - 4, buffers, 3, 1024);
    
    print_to_channel(channel_id, "\x07f1faee[%s] \x071d3557%s: \x07a8dadc%s", buffers[0], buffers[1], buffers[2])
}

void print_discord_msg(const char[] data, int data_size) {
    char buffers[3][1024];
    int channel_id = read_channel_id(data);

    explode_binary(data[4], data_size - 4, buffers, 3, 1024);

    print_to_channel(channel_id, "\x07f1faee[%s] \x071d3557%s: \x07a8dadc%s", buffers[0], buffers[1], buffers[2]);
}

void print_announcement(const char[] data, int data_size) {
    char buffers[2][1024];
    int channel_id = read_channel_id(data);

    explode_binary(data[4], data_size - 4, buffers, 2, 1024);

    print_to_channel(channel_id, "\x07e63946[Annoucement] \x071d3557%s: \x07a8dadc%s", buffers[0], buffers[1]);
}

void parse_server_channels(const char[] data, int data_size) {
    int num_channels = data[0];
    int bytes_consumed = 1;
    for (int c = 0; c < num_channels; c++) {
        if (bytes_consumed >= data_size) {
            break;
        }
        server_channels[c].channel_id = read_channel_id(data[bytes_consumed]);
        bytes_consumed += 4;

        if (bytes_consumed >= data_size) {
            break;
        }
        strcopy(server_channels[c].channel_name, 256, data[bytes_consumed]);
        bytes_consumed += strlen(server_channels[c].channel_name);
    }
}

int read_channel_id(const char[] data) {
    return (data[3]  << 24) || (data[2] << 16) || (data[1] << 8) || data[0];
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