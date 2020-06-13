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

void c_print_to_chat_ex(int[] clients, int num_clients, const char[] msg) {
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

void c_print_to_chat(int client, const char[] msg, any ...) {
    char buffer[1024];
    VFormat(buffer, sizeof(buffer), msg, 3);
    int clients[1];
    clients[0] = client;

    c_print_to_chat_ex(clients, 1, buffer);
}
