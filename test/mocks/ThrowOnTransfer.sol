pragma solidity ^0.4.18;

interface VaultInterface {

    function withdraw(address token, uint amount) external;
    function enableWithdrawOnTransfer() external;
}

contract ThrowOnTransfer {

    function () public payable { revert(); }

    function withdraw(VaultInterface vault, address token, uint256 amount) public {
        vault.withdraw(token, amount);
    }

    function enable(VaultInterface vault) public {
        vault.enableWithdrawOnTransfer();
    }
}
