pragma solidity ^0.4.18;

import "./../../contracts/ExchangeInterface.sol";

contract HookSubscriberMock {

    mapping (address => uint) public tokens;

    function tradeExecuted(address token, uint amount) external {
        tokens[token] += amount;
    }

    function createOrder(address token, uint amount, ExchangeInterface exchange) external {
        exchange.order(
            [token, address(0x0)],
            [amount, 10, (now + 10 days), now]
        );
    }
}
