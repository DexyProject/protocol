pragma solidity ^0.4.18;

import "./VaultInterface.sol";
import "../Tokens/ERC20.sol";
import "../Tokens/ERC777.sol";
import "../Ownership/Ownable.sol";
import "../SafeMath.sol";

contract Vault is Ownable, VaultInterface {

    using SafeMath for *;

    address constant public ETH = 0x0;

    address public exchange;

    // user => exchange => approved
    mapping (address => mapping (address => bool)) approved;
    mapping (address => mapping (address => uint)) balances;
    mapping (address => uint) accounted;

    mapping (address => bool) public isERC777;

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

        if (token != ETH) {
            require(ERC20(token).transferFrom(msg.sender, address(this), value));
        }

        depositFor(msg.sender, token, value);
    }

    function withdraw(address token, uint amount) external {
        require(balanceOf(token, msg.sender) >= amount);

        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        accounted[token] = accounted[token].sub(amount);

        if (token == ETH) {
            msg.sender.transfer(amount);
        } else if (isERC777[token]) {
            ERC777(token).send(msg.sender, amount);
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
        depositFor(from, msg.sender, value);
    }

    function tokensReceived(address operator, address from, address to, uint amount, bytes userData, bytes operatorData) public {
        if (!isERC777[msg.sender]) {
            isERC777[msg.sender] = true;
        }

        depositFor(from, msg.sender, amount);
    }

    function setERC777(address token) public onlyOwner {
        isERC777[token] = true;
    }

    function unsetERC777(address token) public onlyOwner {
        isERC777[token] = false;
    }

    function withdrawOverflow(address token) public onlyOwner {
        if (token == ETH) {
            msg.sender.transfer(overflow(token));
            return;
        }

        ERC20(token).transfer(msg.sender, overflow(token));
    }

    function setExchange(address _exchange) public onlyOwner {
        require(_exchange != 0x0);
        exchange = _exchange;
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    function overflow(address token) internal view returns (uint) {
        if (token == ETH) {
            return this.balance.sub(accounted[token]);
        }

        return ERC20(token).balanceOf(this).sub(accounted[token]);
    }

    function depositFor(address user, address token, uint amount) private {
        balances[token][user] = balances[token][user].add(amount);
        accounted[token] = accounted[token].add(amount);
        Deposited(user, token, amount);
    }
}
