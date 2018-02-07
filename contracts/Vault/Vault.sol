pragma solidity ^0.4.18;

import "./VaultInterface.sol";
import "../Tokens/ERC20.sol";
import "../Ownership/Ownable.sol";
import "../SafeMath.sol";

contract Vault is Ownable, VaultInterface {

    using SafeMath for *;

    address constant public ETH = 0x0;

    address previousExchange;
    address exchange;

    mapping (address => mapping (address => uint)) balances;

    modifier onlyExchange {
        require(msg.sender == exchange);
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

    function transfer(address token, address from, address to, uint amount) external onlyExchange {
        balances[token][from] = balances[token][from].sub(amount);
        balances[token][to] = balances[token][to].add(amount);
    }

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

}