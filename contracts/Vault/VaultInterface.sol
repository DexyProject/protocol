pragma solidity ^0.4.23;

interface VaultInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);

    event Approved(address indexed user, address indexed spender);
    event Unapproved(address indexed user, address indexed spender);

    event AddedSpender(address indexed spender);
    event RemovedSpender(address indexed spender);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function transfer(address token, address from, address to, uint amount) external;
    function approve(address spender) external;
    function unapprove(address spender) external;
    function isApproved(address user, address spender) external view returns (bool);
    function addSpender(address spender) external;
    function removeSpender(address spender) external;
    function latestSpender() external view returns (address);
    function isSpender(address spender) external view returns (bool);
    function tokenFallback(address from, uint value, bytes data) public;
    function balanceOf(address token, address user) public view returns (uint);

}
