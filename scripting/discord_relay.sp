#include <sourcemod>
#include <clientprefs>
#include "include/cryptosocket"

#define CHAT_SYMBOL '#'
// TODO: Clean up this plugin

public Plugin myinfo = {
    name = "Discord Relay",
    author = "Dreae <dreae@dreae.onl>",
    description = "Relays chat between discord and the server",
    version = "0.5.1",
    url = "https://gitlab.com/Dreae/discord_relay.git"
}

ConVar address_cvar = null;
ConVar key_cvar = null;
ConVar key_id_cvar = null;
ConVar advert_cvar = null;
ConVar default_channel_cvar = null;
ConVar default_admin_channel_cvar = null;

#include "discord_relay/channels.sp"
#include "discord_relay/socket.sp"
#include "discord_relay/rate_limit.sp"
#include "discord_relay/client_prefs.sp"
#include "discord_relay/chat.sp"
#include "discord_relay/adverts.sp"

public void OnPluginStart() {
    address_cvar = CreateConVar("discord_relay_address", "", "Address of the discord relay", 0, false, 0.0, false, 0.0);
    key_id_cvar = CreateConVar("discord_relay_key_id", "", "Key ID for the discord relay", 0, false, 0.0, false, 0.0);
    key_cvar = CreateConVar("discord_relay_key", "", "Key for the discord relay", FCVAR_PROTECTED | FCVAR_UNLOGGED, false, 0.0, false, 0.0);
    advert_cvar = CreateConVar("discord_relay_adverts", "1", "Enable discord relaya dverts", 0, false, 0.0, false, 0.0);
    default_channel_cvar = CreateConVar("discord_relay_default_channel", "0", "Default channel clients listen to", 0, false, 0.0, false, 0.0);
    default_admin_channel_cvar = CreateConVar("discord_relay_default_admin_channel", "0", "Default channel clients listen to", 0, false, 0.0, false, 0.0);

    RegServerCmd("discord_relay_list_channels", cmd_list_channels, "List channels this server is listening to", 0);
    listening_channel_cookie = new Cookie("discord_listening_channel", "The channel this client is listening to", CookieAccess_Private);
    admin_channel_cookie = new Cookie("discord_admin_channel", "", CookieAccess_Private);

    AutoExecConfig(true, "discord_relay");

    RegConsoleCmd("sm_discord", cmd_discord, "Change your discord settings", 0);

    address_cvar.AddChangeHook(config_changed);
    key_id_cvar.AddChangeHook(config_changed);
    key_cvar.AddChangeHook(config_changed);
    advert_cvar.AddChangeHook(advert_cvar_changed);

    init_client_settings();
}

public void OnMapStart() {
    request_channels();
    start_reconnect();
}

public void OnClientConnected(int client) {
    init_rate_limit(client);
}

public void OnClientDisconnect(int client) {
    kill_rate_limit(client);
    client_channel_id[client] = 0;
}

public void OnConfigsExecuted() {
    if (advert_cvar.BoolValue) {
        if (advert_timer == null) {
            advert_timer = CreateTimer(120.0, print_advert, _, TIMER_REPEAT);
        }
    }
}

public void OnClientCookiesCached(int client) {
    load_client_prefs(client);
}

public Action cmd_list_channels(int args) {
    int c = 0;
    while(server_channels[c].channel_id != 0) {
        PrintToServer("%%{id: %d, flags: %d, name: \"%s\"}", server_channels[c].channel_id, server_channels[c].channel_flags, server_channels[c].channel_name);
        c++;
    }
    request_channels();
}

Menu build_discord_menu(int client) {
    Menu menu = new Menu(discord_menu_handler);
    int c = 0;
    
    if (client_channel_id[client] == 0) {
        menu.AddItem("0", "[Active] Mute Discord", ITEMDRAW_DISABLED);
    } else {
        menu.AddItem("0", "Mute Discord");
    }
    
    while (server_channels[c].channel_id != 0) {
        if (server_channels[c].admin_channel()) {
            c++;
            continue;
        }

        char channel_id_buffer[12];
        IntToString(server_channels[c].channel_id, channel_id_buffer, sizeof(channel_id_buffer));
        if (client_channel_id[client] == server_channels[c].channel_id) {
            char buffer[255];
            Format(buffer, sizeof(buffer), "[Active] %s", server_channels[c].channel_name);
            menu.AddItem(channel_id_buffer, buffer, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(channel_id_buffer, server_channels[c].channel_name);
        }
        c++;
    }

    menu.SetTitle("Select a discord channel");

    return menu;
}

Menu build_discord_admin_menu(int client) {
    Menu menu = new Menu(discord_admin_menu_handler);
    int c = 0;
    
    if (client_admin_channel_id[client] == 0) {
        menu.AddItem("0", "[Active] Mute Discord", ITEMDRAW_DISABLED);
    } else {
        menu.AddItem("0", "Mute Discord");
    }
    
    while (server_channels[c].channel_id != 0) {
        if (!server_channels[c].admin_channel()) {
            c++;
            continue;
        }

        char channel_id_buffer[12];
        IntToString(server_channels[c].channel_id, channel_id_buffer, sizeof(channel_id_buffer));
        if (client_admin_channel_id[client] == server_channels[c].channel_id) {
            char buffer[255];
            Format(buffer, sizeof(buffer), "[Active] %s", server_channels[c].channel_name);
            menu.AddItem(channel_id_buffer, buffer, ITEMDRAW_DISABLED);
        } else {
            menu.AddItem(channel_id_buffer, server_channels[c].channel_name);
        }
        c++;
    }

    menu.SetTitle("Select a discord admin channel");

    return menu;
}

public int discord_menu_handler(Menu menu, MenuAction action, int client, int param) {
    if (action == MenuAction_Select) {
        char channel_id_buffer[12];

        bool found = menu.GetItem(param, channel_id_buffer, sizeof(channel_id_buffer));
        if (found) {
            int channel_id = StringToInt(channel_id_buffer);
            listening_channel_cookie.Set(client, channel_id_buffer);
            client_channel_id[client] = channel_id;

            if (channel_id == 0) {
                c_print_to_chat(client, "\x07f1faee[Discord] \x07a8dadcMuted discord.");
            } else {
                int c = 0;
                while (server_channels[c].channel_id != 0) {
                    if (server_channels[c].channel_id == channel_id) {
                        c_print_to_chat(client, "\x07f1faee[Discord] \x07a8dadcSwitched channel to %s.", server_channels[c].channel_name);
                        break;
                    }
                    c++;
                }
            }
        }
    }
}

public int discord_admin_menu_handler(Menu menu, MenuAction action, int client, int param) {
    if (action == MenuAction_Select) {
        char channel_id_buffer[12];

        bool found = menu.GetItem(param, channel_id_buffer, sizeof(channel_id_buffer));
        if (found) {
            int channel_id = StringToInt(channel_id_buffer);
            admin_channel_cookie.Set(client, channel_id_buffer);
            client_admin_channel_id[client] = channel_id;

            if (channel_id == 0) {
                c_print_to_chat(client, "\x07f1faee[Discord] \x07a8dadcMuted discord.");
            } else {
                int c = 0;
                while (server_channels[c].channel_id != 0) {
                    if (server_channels[c].channel_id == channel_id) {
                        c_print_to_chat(client, "\x07f1faee[Discord] \x07a8dadcSwitched channel to %s.", server_channels[c].channel_name);
                        break;
                    }
                    c++;
                }
            }
        }
    }
}

public int discord_top_menu_handler(Menu top_menu, MenuAction action, int client, int param) {
    if (action == MenuAction_Select) {
        char action_buffer[12];
        bool found = top_menu.GetItem(param, action_buffer, sizeof(action_buffer));
        if (found) {
            if (strcmp(action_buffer, "main", false) == 0) {
                Menu menu = build_discord_menu(client);
                menu.Display(client, MENU_TIME_FOREVER);
            } else {
                Menu menu = build_discord_admin_menu(client);
                menu.Display(client, MENU_TIME_FOREVER);
            }
        }
    }
}

public Action cmd_discord(int client, int args) {
    AdminId admin = GetUserAdmin(client);
    if (admin != INVALID_ADMIN_ID && admin.HasFlag(Admin_Kick, Access_Effective)) {
        Menu menu = new Menu(discord_top_menu_handler);
        menu.AddItem("main", "Discord Channels");
        menu.AddItem("admin", "Admin Channels");
        menu.SetTitle("Discord Channel Menu");

        menu.Display(client, MENU_TIME_FOREVER);
    } else {
        Menu menu = build_discord_menu(client);
        menu.Display(client, MENU_TIME_FOREVER);
    }
    
    return Plugin_Handled;
}

public void config_changed(ConVar convar, const char[] old_value, const char[] new_value) {
    start_reconnect();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
    if (args[0] != CHAT_SYMBOL) {
        return Plugin_Continue;
    }

    if (strcmp(command, "say", false) != 0 && strcmp(command, "say_team", false) != 0) {
        return Plugin_Continue;
    }

    if (!IsClientAuthorized(client) || !IsClientInGame(client) || !AreClientCookiesCached(client)) {
        return Plugin_Continue;
    }

    if (socket != INVALID_HANDLE && socket.Connected()) {
        int channel_id = client_channel_id[client];
        if (strcmp(command, "say_team", false) == 0) {
            AdminId admin = GetUserAdmin(client);
            if (admin == INVALID_ADMIN_ID || !admin.HasFlag(Admin_Kick, Access_Effective)) {
                c_print_to_chat(client, "\x07f1faee[Discord] \x07a8dadcYou don't have access to this command");
                return Plugin_Stop;
            }
            channel_id = client_admin_channel_id[client];
        }

        if (channel_id == 0xffffffff || channel_id == 0) {
            return Plugin_Stop;
        }

        if (client_rate_limits[client].tokens <= 0) {
            c_print_to_chat(client, "\x07f1faee[Discord] \x07a8dadcYou are rate limited, please wait before sending another message.");
            return Plugin_Stop;
        }

        char buffer[1028];
        strcopy(buffer, sizeof(buffer), "\xff\xff\xff\x01");

        char steam_id[32];
        GetClientAuthId(client, AuthId_Steam3, steam_id, sizeof(steam_id), true);

        char name[128];
        GetClientName(client, name, sizeof(name));

        add_channel_id(channel_id, buffer[4]);

        int steam_id_size = strlen(steam_id);
        int name_size = strlen(name);
        int msg_size = strlen(args);
        
        strcopy(buffer[8], sizeof(buffer), steam_id);
        buffer[steam_id_size + 8] = '\0';

        strcopy(buffer[steam_id_size + 9], sizeof(buffer) - (steam_id_size + 10), name);
        buffer[steam_id_size + 9 + name_size] = '\0';

        strcopy(buffer[steam_id_size + name_size + 10], sizeof(buffer) - (steam_id_size + name_size + 11), args[1]);

        socket.Send(buffer, steam_id_size + name_size + msg_size + 11);
        client_rate_limits[client].tokens--;

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void add_channel_id(int channel_id, char[] buffer) {
    buffer[0] = (channel_id >> 24) & 0xff;
    buffer[1] = (channel_id >> 16) & 0xff;
    buffer[2] = (channel_id >> 8) & 0xff;
    buffer[3] = channel_id & 0xff;
}
