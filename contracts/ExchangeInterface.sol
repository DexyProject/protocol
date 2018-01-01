pragma solidity ^0.4.18;

interface ExchangeInterface {

    function deposit() external payable;
    function depositToken(address token, uint amount) external;
    function withdraw(address token, uint amount) external;
    function balanceOf(address token, address user) public view returns (uint);
    function canTrade() public view returns (bool);

}
