#if defined __cryptosocket_included
    #endinput
#endif
#define __cryptosocket_included
#define CRYPTOSOCKET_VERSION "1.0.0"

typedef DataCallback = function void (const char[] data, int data_size);

methodmap EncryptedSocket < Handle {
    public native EncryptedSocket(const char[] key_id, const char[] key, DataCallback callback);
    public native void Send(const char[] data, int data_size);
    public native void Connect(const char[] address, int port);
    public native bool Connected();
}

public Extension:__ext_cryptosocket = {
    name = "CryptoSocket",
    file = "cryptosocket.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};