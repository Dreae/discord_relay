#define CHANNEL_FLAG_ADMIN      (1<<0)
#define CHANNEL_FLAG_PROTECTED  (1<<1)
#define CHANNEL_FLAG_RECV_ALL   (1<<2)

enum struct channel {
    int channel_id;
    char channel_name[255];
    int channel_flags;

    bool admin_channel() {
        return this.channel_flags & CHANNEL_FLAG_ADMIN == CHANNEL_FLAG_ADMIN;
    }
}

channel server_channels[256];

int client_channel_id[MAXPLAYERS];
int client_admin_channel_id[MAXPLAYERS];

bool get_channel(int channel_id, channel chnl) {
    int c = 0;
    while (server_channels[c].channel_id != 0) {
        if (server_channels[c].channel_id == channel_id) {
            chnl = server_channels[c];
            return true;
        }
        c++;
    }

    return false;
}

void parse_server_channels(const char[] data, int data_size) {
    int num_channels = data[0];
    LogMessage("Channel update, reading %d channels", num_channels);

    int bytes_consumed = 1;
    for (int c = 0; c < num_channels; c++) {
        if (bytes_consumed >= data_size) {
            break;
        }
        server_channels[c].channel_id = read_channel_id(data[bytes_consumed]);
        bytes_consumed += 4;
        
        server_channels[c].channel_flags = read_channel_flags(data[bytes_consumed]);
        bytes_consumed += 2;

        if (bytes_consumed >= data_size) {
            break;
        }
        strcopy(server_channels[c].channel_name, 256, data[bytes_consumed]);
        bytes_consumed += strlen(server_channels[c].channel_name) + 1;
    }
}

int read_channel_id(const char[] data) {
    return (data[0]  << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
}

int read_channel_flags(const char[] data) {
    return (data[0] << 8) | data[1];
}

void print_to_channel(int channel_id, const char[] msg, any ...) {
    char buffer[1024];
    VFormat(buffer, sizeof(buffer), msg, 3);
    int[] clients = new int[MaxClients];
    int num_clients = 0;

    channel chnl;
    if (get_channel(channel_id, chnl)) {
        if (chnl.admin_channel()) {
            Format(buffer, sizeof(buffer), "\x07e63946Admins %s", buffer);
        }
        
        for (int client = 1; client <= MaxClients; client++) {
            if (!AreClientCookiesCached(client)) {
                continue;
            }

            if (chnl.admin_channel()) {
                AdminId admin = GetUserAdmin(client);
                if (admin != INVALID_ADMIN_ID && admin.HasFlag(Admin_Kick, Access_Effective)) {
                    int client_admin_channel = client_admin_channel_id[client];
                    if (client_admin_channel == channel_id || client_admin_channel == 0xffffffff) {
                        clients[num_clients] = client;
                        num_clients++;
                    }
                }
            } else {
                int client_channel = client_channel_id[client];
                if (client_channel == channel_id || client_channel == 0xffffffff) {
                    clients[num_clients] = client;
                    num_clients++;
                }
            }
        }

        c_print_to_chat_ex(clients, num_clients, buffer);
    }
}