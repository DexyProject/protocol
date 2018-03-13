pragma solidity ^0.4.18;

contract SelfDestructor {

    function () public payable { }

    function destroy(address vault) public {
        selfdestruct(vault);
    }
}
