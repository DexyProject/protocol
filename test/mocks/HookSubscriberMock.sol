pragma solidity ^0.4.18;

contract HookSubscriberMock {

    mapping (address => uint) public tokens;

    function tradeExecuted(address token, uint amount) external {
        tokens[token] += amount;
    }

    // @todo create order etc.
}
