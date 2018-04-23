pragma solidity ^0.4.21;

import "./Vault/VaultInterface.sol";

interface ExchangeInterface {

    event Subscribed(address indexed user);
    event Unsubscribed(address indexed user);

    event Cancelled(bytes32 indexed hash);

    event Traded(
        bytes32 indexed hash,
        address makerToken,
        uint makerTokenAmount,
        address takerToken,
        uint takerTokenAmount,
        address maker,
        address taker
    );

    event Ordered(
        address maker,
        address makerToken,
        address takerToken,
        uint makerTokenAmount,
        uint takerTokenAmount,
        uint expires,
        uint nonce
    );

    function subscribe() external;
    function unsubscribe() external;

    function trade(address[3] addresses, uint[4] values, bytes signature, uint maxFillAmount) external;
    function cancel(address[3] addresses, uint[4] values) external;
    function order(address[2] addresses, uint[4] values) external;

    function canTrade(address[3] addresses, uint[4] values, bytes signature)
        external
        view
        returns (bool);

    function isSubscribed(address subscriber) external view returns (bool);
    function availableAmount(address[3] addresses, uint[4] values) external view returns (uint);
    function filled(bytes32 hash) external view returns (uint);
    function isOrdered(address user, bytes32 hash) public view returns (bool);
    function vault() public view returns (VaultInterface);

}
