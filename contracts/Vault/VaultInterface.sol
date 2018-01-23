pragma solidity ^0.4.18;

interface VaultInterface {

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function transfer(address token, address from, address to, uint amount) external;
    function balanceOf(address token, address user) public view returns (uint);

}
