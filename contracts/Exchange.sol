pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./SafeMath.sol";
import "./Tokens/ERC20.sol";
import "./Ownership/Ownable.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;

    mapping (bytes32 => bool) cancelled;

    /// (token => (user => balance))
    mapping (address => mapping (address => uint)) balances;

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);
    event Traded();

    function Exchange() public { }

    function deposit(address token, uint amount) external payable {
        require(token == 0x0 || msg.value = 0);

        if (token != 0x0) {
            require(ERC20(token).transferFrom(msg.sender, address(this), amount));
        } else {
            amount = msg.value;
        }

        balances[token][msg.sender] = balances[token][msg.sender].add(amount);
        Deposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint amount) external {
        require(balanceOf(token, msg.sender) >= amount);

        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);

        if (token == 0x0) {
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
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    function canTrade() public view returns (bool) {
        return false;
    }

    function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash), v, r, s) == addr;
    }
}
