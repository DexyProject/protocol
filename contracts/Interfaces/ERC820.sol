pragma solidity ^0.4.21;

interface ERC820 {

    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;

}
