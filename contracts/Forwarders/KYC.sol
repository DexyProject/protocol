pragma solidity ^0.4.18;

import "./../Exchange.sol";
import "./ForwarderInterface.sol";

contract KYC is ForwarderInterface {

    Exchange public exchange;

    function trade(
        address[3] addresses,
        uint[4] values,
        bytes sig,
        uint maxFillAmount,
        uint nonce,
        bytes takerSig
    )
        external
    {
        // @todo checks
        exchange.tradeFor(addresses, values, sig, maxFillAmount, nonce, takerSig);
    }

    function isPermitted(address user) external view returns (bool) {
        // @todo
        return false;
    }
}
