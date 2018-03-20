pragma solidity ^0.4.20;

interface ExchangeInterface {

    event Cancelled(bytes32 indexed hash);
    event Traded(bytes32 indexed hash, address tokenGive, uint amountGive, address tokenGet, uint amountGet, address maker, address taker);

    function trade(address[3] addresses, uint[4] values, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode) external;
    function cancel(address[3] addresses, uint[4] values) external;
    function canTrade(address[3] addresses, uint[4] values, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode) external view returns (bool);
    function filled(address user, bytes32 hash) external view returns (uint);
    function getVolume(uint amountGet, address tokenGive, uint amountGive, address user, bytes32 hash) public view returns (uint);

}
