pragma solidity ^0.4.18;

interface ExchangeInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);
    event Cancelled(bytes32 indexed hash);
    event Traded(bytes32 indexed hash, uint amountGive, uint amountGet);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode) external;
    function cancel(uint expires, uint amountGive, uint amountGet, address tokenGet, address tokenGive, uint nonce, uint8 v, bytes32 r, bytes32 s, uint mode) external;
    function balanceOf(address token, address user) public view returns (uint);
    function canTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode, bytes32 hash) public view returns (bool);

}
