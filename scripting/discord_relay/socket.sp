EncryptedSocket socket = null;
float connection_attempt = 0.0;

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
        } else if (data[3] == '\x04') {
            print_announcement(data[4], data_size - 4);
        } else if (data[3] == '\x06') {
            parse_server_channels(data[4], data_size - 5);
        }
    }
}

void print_server_msg(const char[] data, int data_size) {
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
