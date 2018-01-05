pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./SafeMath.sol";
import "./Tokens/ERC20.sol";
import "./Ownership/Ownable.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;

    address constant ETH = 0x0;

	/// exchange parameters
	uint makerFee = 0;
	uint takerFee = 0;
	address feeAccount;

    /// state maps
    mapping (address => mapping (address => uint)) balances;
	mapping (address => mapping (bytes32 => uint)) fills;
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

	function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {

		bytes32 hash = sha256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, this);

		if (
			!didSign(msg.sender, hash, v, r, s)
			|| now >= expires
			|| fills[user][hash].add(amount) >= amountGet
		   )
			revert();

		performTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount);
		fills[user][hash] = fills[user][hash].add(amount);
		Traded();
	}

    function cancel(uint expires, uint amountGive, uint amountGet, address tokenGet, address tokenGive, uint nonce, uint8 v, bytes32 r, bytes32 s) external {
		bytes32 hash = sha256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, this);
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

	function performTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) internal {

		uint tradeTakerFee = amount.mul(takerFee).div(1 ether);
		uint tradeMakerFee = amount.mul(makerFee).div(1 ether);


		balances[tokenGet][msg.sender] = balances[tokenGet][msg.sender].sub(amount.add(tradeTakerFee));
		balances[tokenGet][user] = balances[tokenGet][user].add(amount.sub(tradeMakerFee));
		balances[tokenGet][feeAccount] = balances[tokenGet][feeAccount].add(amount.add(tradeTakerFee).add(tradeMakerFee));
		balances[tokenGive][user] = balances[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
		balances[tokenGive][msg.sender] = balances[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));

	}

	function setFees(uint _makerFee, uint _takerFee) onlyOwner public {
		makerFee = _makerFee;
		takerFee = _takerFee;
	}

	function setFeeAccount(address _feeAccount) onlyOwner public {
		feeAccount = _feeAccount;
	}

    function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == addr;
    }
}
