pragma solidity ^0.4.23;

interface ConnectorInterface {

    function register() external;
    function deposit(address token, address user, uint amount) external;
    function withdraw(address token, address user, uint amount) external;
    function balanceOf(address token, address user) external returns (uint);
    function receiver() external returns (bytes4);

}
