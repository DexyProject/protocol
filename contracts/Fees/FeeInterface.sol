pragma solidity ^0.4.18;

interface FeeInterface {

    function fees(address user) external view returns (uint);

}
