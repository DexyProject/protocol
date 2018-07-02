pragma solidity ^0.4.23;

interface HookSubscriber {

    function tradeExecuted(address token, uint amount) external;

}
