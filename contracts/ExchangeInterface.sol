pragma solidity ^0.4.18;

import "./Vault/VaultInterface.sol";

interface ExchangeInterface {

    event Cancelled(bytes32 indexed hash);

    event Traded(
        bytes32 indexed hash,
        address tokenGive,
        uint amountGive,
        address tokenGet,
        uint amountGet,
        address maker,
        address taker
    );

    event Ordered(
        address user,
        address tokenGive,
        address tokenGet,
        uint amountGive,
        uint amountGet,
        uint expires,
        uint nonce
    );

    function trade(address[3] addresses, uint[4] values, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode)
        external;

    function cancel(address[3] addresses, uint[4] values) external;

    function order(address[2] addresses, uint[4] values) external;

    function canTrade(address[3] addresses, uint[4] values, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode)
        external
        view
        returns (bool);

    function filled(address user, bytes32 hash) external view returns (uint);

    function isOrdered(address user, bytes32 hash) public view returns (bool);

    function vault() public view returns (VaultInterface);

}
