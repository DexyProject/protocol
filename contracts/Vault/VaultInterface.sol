pragma solidity ^0.4.21;

interface VaultInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function transfer(address token, address from, address to, uint amount) external;
    function approve(address exchange) external;
    function unapprove(address exchange) external;
    function isApproved(address user, address exchange) external view returns (bool);
    function isSpender(address spender) external view returns (bool);
    function tokenFallback(address from, uint value, bytes data) public;
    function balanceOf(address token, address user) public view returns (uint);

}
