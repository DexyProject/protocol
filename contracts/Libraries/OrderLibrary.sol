pragma solidity ^0.4.21;

library OrderLibrary {

    bytes32 constant public HASH_SCHEME = keccak256(
        "address Taker Token",
        "uint Taker Get",
        "address Maker Token",
        "uint Maker Get",
        "uint Expires",
        "uint Nonce",
        "address Maker",
        "address Exchange"
    );

    struct Order {
        address maker;
        address makerToken;
        address takerToken;
        uint takerGet;
        uint makerGet;
        uint expires;
        uint nonce;
    }

    /// @dev Hashes the order.
    /// @param order Order to be hashed.
    /// @return hash result
    function hash(Order memory order) internal view returns (bytes32) {
        return keccak256(
            HASH_SCHEME,
            keccak256(
                order.takerToken,
                order.makerGet,
                order.makerToken,
                order.takerGet,
                order.expires,
                order.nonce,
                order.maker,
                this
            )
        );
    }

    /// @dev Creates order struct from value arrays.
    /// @param addresses Array of trade's user, makerToken and takerToken.
    /// @param values Array of trade's takerGet, makerGet, expires and nonce.
    /// @return Order struct
    function createOrder(address[3] addresses, uint[4] values) internal pure returns (Order memory) {
        return Order({
            maker: addresses[0],
            makerToken: addresses[1],
            takerToken: addresses[2],
            takerGet: values[0],
            makerGet: values[1],
            expires: values[2],
            nonce: values[3]
        });
    }
}
