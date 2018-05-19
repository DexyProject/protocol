pragma solidity ^0.4.18;

import "./../Exchange.sol";
import "./ForwarderInterface.sol";

contract KYC is ForwarderInterface {

    Exchange public exchange;

    struct GroupPerms {
        uint kycGroupId;
        uint tradeLimits;
        mapping (address => bool) allowedMarket;
    }

    mapping (address => GroupPerms) addressGroup;

    address RingValidator;

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
        require(isPermitted(msg.sender));

        exchange.tradeFor(addresses, values, sig, maxFillAmount, nonce, takerSig);
    }

    function isPermitted(address user) public view returns (bool) {
        if (addressGroup[user].kycGroupId == 0){
            return true;
        }
        else {
            return false;
        }
    }

    function addGroup(kycId, allowedMarket, address[] users){
        require(msg.sender == RingValidator);

        // user defined
    }
}
