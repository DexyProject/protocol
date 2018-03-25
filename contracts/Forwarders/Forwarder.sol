pragma solidity ^0.4.18;

import "./../ExchangeInterface.sol";
import "./../Libraries/OrderLibrary.sol";

contract Forwarder {

    ExchangeInterface public exchange;

    function Forwarder(ExchangeInterface _exchange) {
        require(address(_exchange) != 0x0);
        exchange = _exchange;
    }

    function trade(address[3] addresses, uint[4] values, uint fillAmount, bytes signature) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        exchange.vault().deposit(order.tokenGet, order.amountGet);
        exchange.trade(addresses, values, fillAmount, signature);
        exchange.vault().withdraw(order.tokenGive, order.amountGive);
    }
}
