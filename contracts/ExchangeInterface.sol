pragma solidity ^0.4.18;

interface ExchangeInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);
    event Cancelled(bytes32 indexed hash);
    event Traded(bytes32 indexed hash, uint tokenGive, uint amountGive, uint tokenGet, uint amountGet, address maker, address taker);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function trade(address[3] addresses, uint[4] values, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode) external;
    function cancel(address[3] addresses, uint[4] values, uint8 v, bytes32 r, bytes32 s, uint mode) external;
    function balanceOf(address token, address user) public view returns (uint);
    function filled(address user, bytes32 hash) public view returns (uint);
    function canTrade(address[3] addresses, uint[4] values, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode) public view returns (bool);
    function getVolume(uint amountGet, address tokenGive, uint amountGive, address user, bytes32 hash) public view returns (uint);

}
