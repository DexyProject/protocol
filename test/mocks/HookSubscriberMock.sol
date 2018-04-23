pragma solidity ^0.4.18;

import "./../../contracts/ExchangeInterface.sol";

contract HookSubscriberMock {

    mapping (address => uint) public tokens;

    function tradeExecuted(address token, uint amount) external {
        tokens[token] += amount;
    }

    function createOrder(address[2] addresses, uint[4] values, ExchangeInterface exchange) external {
        exchange.subscribe();
        exchange.vault().approve(exchange);
        exchange.vault().deposit(addresses[0], values[0]);
        exchange.order(addresses, values);
    }
}
