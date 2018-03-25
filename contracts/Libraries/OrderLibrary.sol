pragma solidity ^0.4.18;

library OrderLibrary {

    bytes32 constant public HASH_SCHEME = keccak256(
        "address Token Get",
        "uint Amount Get",
        "address Token Give",
        "uint Amount Give",
        "uint Expires",
        "uint Nonce",
        "address User",
        "address Exchange"
    );

    struct Order {
        address user;
        address tokenBid;
        address tokenAsk;
        uint amountBid;
        uint amountAsk;
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
                order.tokenAsk,
                order.amountAsk,
                order.tokenBid,
                order.amountBid,
                order.expires,
                order.nonce,
                order.user,
                this
            )
        );
    }

    /// @dev Creates order struct from value arrays.
    /// @param addresses Array of trade's user, tokenBid and tokenAsk.
    /// @param values Array of trade's amountBid, amountAsk, expires and nonce.
    /// @return Order struct
    function createOrder(address[3] addresses, uint[4] values) internal pure returns (Order memory) {
        return Order({
            user: addresses[0],
            tokenBid: addresses[1],
            tokenAsk: addresses[2],
            amountBid: values[0],
            amountAsk: values[1],
            expires: values[2],
            nonce: values[3]
        });
    }
}
