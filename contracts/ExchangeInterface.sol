pragma solidity ^0.4.18;

interface ExchangeInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);
    event Cancelled(bytes32 indexed hash);
    event Traded();

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function balanceOf(address token, address user) public view returns (uint);
    function canTrade() public view returns (bool);

}
