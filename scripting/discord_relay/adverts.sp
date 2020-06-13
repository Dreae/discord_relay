Handle advert_timer = null;
int advert_idx = 0;
char adverts[2][] = {
    "\x07f1faee[Discord] \x07a8dadcThis server is connected to discord. Put a \x07e63946# \x07a8dadcin front of your message to chat with discord.",
    "\x07f1faee[Discord] \x07a8dadcUse \x07e63946!discord \x07a8dadcto change your discord channel."
};

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
        c_print_to_chat_all(adverts[advert_idx]);
        advert_idx++;

        if (advert_idx == sizeof(adverts)) {
            advert_idx = 0;
        }
    }
    return Plugin_Continue;
}