pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./SafeMath.sol";
import "./Tokens/ERC20.sol";
import "./Ownership/Ownable.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;

    address constant ETH = 0x0;

    /// (token => (user => balance))
    mapping (address => mapping (address => uint)) balances;
    mapping (bytes32 => bool) cancelled;

    function Exchange() public { }

    function deposit(address token, uint amount) external payable {
        require(token == ETH || msg.value == 0);

        uint value = amount;
        if (token == ETH) {
            value = msg.value;
        }

        balances[token][msg.sender] = balances[token][msg.sender].add(value);

        if (token != ETH) {
            require(ERC20(token).transferFrom(msg.sender, address(this), value));
        }

        Deposited(msg.sender, token, value);
    }

    function withdraw(address token, uint amount) external {
        require(balanceOf(token, msg.sender) >= amount);

        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);

        if (token == ETH) {
            msg.sender.transfer(amount);
        } else {
            ERC20(token).transfer(msg.sender, amount);
        }

        Withdrawn(msg.sender, token, amount);
    }

    function cancel(uint expires, uint amountGive, uint amountGet, address tokenGet, address tokenGive, uint nonce, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(expires, amountGive, amountGet, tokenGet, tokenGive, nonce);
        require(didSign(msg.sender, hash, v, r, s));

        cancelled[hash] = true;
        Cancelled(hash);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    function canTrade() public view returns (bool) {
        return false;
    }

    function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == addr;
    }
}
