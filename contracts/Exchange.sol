pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./SafeMath.sol";
import "./Tokens/ERC20.sol";
import "./Ownership/Ownable.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;

    /// (token => user => balance)
    mapping (address => mapping (address => uint)) balances;

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);
    event Traded();

    function Exchange() public { }

    function deposit() external payable {

    }

    function depositToken(address token, uint amount) external {
        require(ERC20(token).transferFrom(msg.sender, address(this), amount));
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

    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    function canTrade() public view returns (bool) {
        return false;
    }
}
