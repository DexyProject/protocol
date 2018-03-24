pragma solidity ^0.4.18;

import "./VaultInterface.sol";
import "../Libraries/SafeMath.sol";
import "../Ownership/Ownable.sol";
import "../Tokens/ERC20.sol";
import "../Tokens/ERC777.sol";

contract Vault is Ownable, VaultInterface {

    using SafeMath for *;

    address constant public ETH = 0x0;

    address public exchange;

    // user => exchange => approved
    mapping (address => mapping (address => bool)) private approved;
    mapping (address => mapping (address => uint)) private balances;
    mapping (address => uint) private accounted;

    mapping (address => bool) public isERC777;

    modifier onlyApproved(address user) {
        require(msg.sender == exchange && approved[user][exchange]);
        _;
    }

    /// @dev Deposits a specific token.
    /// @param token Address of the token to deposit.
    /// @param amount Amount of tokens to deposit.
    function deposit(address token, uint amount) external payable {
        require(token == ETH || msg.value == 0);

        uint value = amount;
        if (token == ETH) {
            value = msg.value;
        } else {
            require(ERC20(token).transferFrom(msg.sender, address(this), value));
        }

        depositFor(msg.sender, token, value);
    }

    /// @dev Withdraws a specific token.
    /// @param token Address of the token to withdraw.
    /// @param amount Amount of tokens to withdraw.
    function withdraw(address token, uint amount) external {
        require(balanceOf(token, msg.sender) >= amount);

        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        accounted[token] = accounted[token].sub(amount);

        if (token == ETH) {
            msg.sender.transfer(amount);
        } else if (isERC777[token]) {
            ERC777(token).send(msg.sender, amount);
        } else {
            require(ERC20(token).transfer(msg.sender, amount));
        }

        Withdrawn(msg.sender, token, amount);
    }

    /// @dev Approves an exchange to trade balances of the sender.
    /// @param _exchange Address of the exchange to approve.
    function approve(address _exchange) external {
        require(exchange == _exchange);
        approved[msg.sender][exchange] = true;
    }

    /// @dev Unapproves an exchange to trade balances of the sender.
    /// @param _exchange Address of the exchange to unapprove.
    function unapprove(address _exchange) external {
        approved[msg.sender][_exchange] = false;
    }

    /// @dev Transfers balances of a token between users.
    /// @param token Address of the token to transfer.
    /// @param from Address of the user to transfer tokens from.
    /// @param to Address of the user to transfer tokens to.
    /// @param amount Amount of tokens to transfer.
    function transfer(address token, address from, address to, uint amount) external onlyApproved(from) {
        // We do not check the balance here, as SafeMath will revert if sub / add fail. Due to over/underflows.
        balances[token][from] = balances[token][from].sub(amount);
        balances[token][to] = balances[token][to].add(amount);
    }

    /// @dev Returns if an exchange has been approved by a user.
    /// @param user Address of the user.
    /// @param _exchange Address of the exchange.
    /// @return Boolean whether exchange has been approved.
    function isApproved(address user, address _exchange) external view returns (bool) {
        return approved[user][_exchange];
    }

    function tokenFallback(address from, uint value, bytes) public {
        depositFor(from, msg.sender, value);
    }

    function tokensReceived(address, address from, address, uint amount, bytes, bytes) public {
        if (!isERC777[msg.sender]) {
            isERC777[msg.sender] = true;
        }

        depositFor(from, msg.sender, amount);
    }

    /// @dev Marks a token as an ERC777 token.
    /// @param token Address of the token.
    function setERC777(address token) public onlyOwner {
        isERC777[token] = true;
    }

    /// @dev Unmarks a token as an ERC777 token.
    /// @param token Address of the token.
    function unsetERC777(address token) public onlyOwner {
        isERC777[token] = false;
    }

    /// @dev Allows owner to withdraw tokens accidentally sent to the contract.
    /// @param token Address of the token to withdraw.
    function withdrawOverflow(address token) public onlyOwner {
        if (token == ETH) {
            msg.sender.transfer(overflow(token));
            return;
        }

        if (isERC777[token]) {
            ERC777(token).send(msg.sender, overflow(token));
            return;
        }

        require(ERC20(token).transfer(msg.sender, overflow(token)));
    }

    /// @dev Allows the owner to change the current exchange.
    /// @param _exchange Address of the exchange.
    function setExchange(address _exchange) public onlyOwner {
        require(_exchange != 0x0);
        exchange = _exchange;
    }

    /// @dev Returns the balance of a user for a specified token.
    /// @param token Address of the token.
    /// @param user Address of the user.
    /// @return Balance for the user.
    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    /// @dev Calculates how many tokens were accidentally sent to the contract.
    /// @param token Address of the token to calculate for.
    /// @return Amount of tokens not accounted for.
    function overflow(address token) internal view returns (uint) {
        if (token == ETH) {
            return this.balance.sub(accounted[token]);
        }

        return ERC20(token).balanceOf(this).sub(accounted[token]);
    }

    /// @dev Accounts for token deposits.
    /// @param user Address of the user who deposited.
    /// @param token Address of the token deposited.
    /// @param amount Amount of tokens deposited.
    function depositFor(address user, address token, uint amount) private {
        balances[token][user] = balances[token][user].add(amount);
        accounted[token] = accounted[token].add(amount);
        Deposited(user, token, amount);
    }
}
