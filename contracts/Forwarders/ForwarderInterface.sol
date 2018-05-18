pragma solidity ^0.4.18;

interface ForwarderInterface {

    function trade(
        address[3] addresses,
        uint[4] values,
        bytes sig,
        uint maxFillAmount,
        uint nonce,
        bytes takerSig
    ) external;

    function isPermitted(address user) external view returns (bool);

}
