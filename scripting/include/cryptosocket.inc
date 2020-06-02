#if defined __cryptosocket_included
    #endinput
#endif
#define __cryptosocket_included
#define CRYPTOSOCKET_VERSION "1.0.1"

/**
 * Callback for receiving decrypted data from an EncryptedSocket
 *
 * @param data                A buffer containing the data received. Not that
 *                            this buffer should be treated as binary data and
 *                            can contain null characters before the end of the
 *                            data.
 * @param data_size           The size of the data received
 */
typedef DataCallback = function void (const char[] data, int data_size);
typedef ConnectionCallback = function void (EncryptedSocket socket);

methodmap EncryptedSocket < Handle {
    /**
     * Creates a new EncryptedSocket using the provided key ID and key, and registers
     * the provided callback to handle data received from the other end of the socket.
     *
     * @param key_id              The key ID to be sent to the server during the handshake.
     *                            The intention is for the server implementation to use this
     *                            key ID to lookup the corrisponding shared key, which enables
     *                            a single server instance to handle connections from many
     *                            EncryptedSockets.
     * @param key                 The shared key used for authentication this socket during
     *                            the handshake
     * 
     * @return                    The newly created EncryptedSocket
     */
    public native EncryptedSocket(const char[] key_id, const char[] key, DataCallback callback);

    /**
     * Connects this encrypted socket to the given address and port.
     *
     * @param address             The IP address or domain name to connect to
     * @param port                The port to connect to
     * @param connect_callback    Optional callback to call once the socket is connected
     */
    public native void Connect(const char[] address, int port, ConnectionCallback connect_callback=INVALID_FUNCTION);

    /**
     * Tests if this socket is currently connected to another EncryptedSocket
     *
     * @return                    The connection status
     */
    public native bool Connected();

    /**
     * Encrypts the provided data and sends it to the server this socket is connected to
     * Raises an error if the socket is unconnected.
     * 
     * @param data                The data to encrypt and transmit. This data is treated
     *                            as binary data and may contain null characters.
     * @param data_size           The length of the provided data. Note that it is important
     *                            to only set this to the amount of data you intend to write,
     *                            not the size of the provided buffer, otherwise the garbage
     *                            at the end of the buffer will also be sent.
     */
    public native void Send(const char[] data, int data_size);

    /**
     * Adds a disconnect callback to this socket.
     * 
     * @param callback            The callback which will be called if this socket is
     *                            disconnected from the remote endpoint.
     */
    public native void OnDisconnected(ConnectionCallback callback);
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