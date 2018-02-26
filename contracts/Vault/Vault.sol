pragma solidity ^0.4.18;

import "./VaultInterface.sol";
import "../Tokens/ERC20.sol";
import "../Ownership/Ownable.sol";
import "../SafeMath.sol";

contract Vault is Ownable, VaultInterface {

    using SafeMath for *;

    address constant public ETH = 0x0;

    address public exchange;

    // user => exchange => approved
    mapping (address => mapping (address => bool)) approved;
    mapping (address => mapping (address => uint)) balances;

    modifier onlyApproved(address user) {
        require(msg.sender == exchange && approved[user][exchange]);
        _;
    }

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

    function approve(address _exchange) external {
        require(exchange == _exchange);
        approved[msg.sender][exchange] = true;
    }

    function unapprove(address exchange) external {
        approved[msg.sender][exchange] = false;
    }

    function transfer(address token, address from, address to, uint amount) external onlyApproved(from) {
        balances[token][from] = balances[token][from].sub(amount);
        balances[token][to] = balances[token][to].add(amount);
    }

    function isApproved(address user, address exchange) external view returns (bool) {
        return approved[user][exchange];
    }

    function tokenFallback(address from, uint value, bytes data) public {
        balances[msg.sender][from] = balances[msg.sender][from].add(value);
        Deposited(from, msg.sender, value);
    }

    function setExchange(address _exchange) public onlyOwner {
        require(_exchange != 0x0);
        exchange = _exchange;
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

}
