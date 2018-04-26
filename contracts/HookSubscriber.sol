pragma solidity ^0.4.21;

interface HookSubscriber {

    function tradeExecuted(address token, uint amount) external;

}
