pragma solidity ^0.4.18;

interface ExchangeInterface {

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function balanceOf(address token, address user) public view returns (uint);
    function canTrade() public view returns (bool);

}
