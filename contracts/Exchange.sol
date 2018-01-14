pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./SafeMath.sol";
import "./Ownership/Ownable.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;

    address constant ETH = 0x0;

    uint makerFee = 0;
    uint takerFee = 0;
    address feeAccount;

    mapping (address => mapping (bytes32 => uint)) fills;
    mapping (bytes32 => bool) cancelled;

    function Exchange() public { }

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) external {
        require(msg.sender != user);
        bytes32 hash = keccak256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, this);
        require(canTrade(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s, amount, hash));

        performTrade(tokenGet, amountGet, tokenGive, amountGive, user, amount, hash);
        Traded(hash, amount);
    }

    function cancel(uint expires, uint amountGive, uint amountGet, address tokenGet, address tokenGive, uint nonce, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, this);
        require(didSign(msg.sender, hash, v, r, s));

        cancelled[hash] = true;
        Cancelled(hash);
    }

    function canTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, bytes32 hash) public view returns (bool) {

        if (!didSign(user, hash, v, r, s)) {
             return false;
        }

        if (cancelled[hash]) {
            return false;
        }

        require(balances[tokenGet][msg.sender] >= amount);
        require(getVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user) >= amount);

        return expires >= now && fills[user][hash].add(amount) >= amountGet;
    }

    function getVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns (uint) {
        bytes32 hash = keccak256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, this);

        uint availableTaker = amountGet.sub(fills[user][hash]);
        uint availableMaker = balances[tokenGive][user].mul(amountGet).div(amountGive);

        return (availableTaker < availableMaker) ? availableTaker : availableMaker;
    }

    function setFees(uint _makerFee, uint _takerFee) public onlyOwner {
        makerFee = _makerFee;
        takerFee = _takerFee;
    }

    function setFeeAccount(address _feeAccount) public onlyOwner {
        feeAccount = _feeAccount;
    }

    function performTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount, bytes32 hash) internal {
        uint tradeTakerFee = amount.mul(takerFee).div(1 ether);
        uint tradeMakerFee = amount.mul(makerFee).div(1 ether);

        balances[tokenGet][msg.sender] = balances[tokenGet][msg.sender].sub(amount.add(tradeTakerFee));
        balances[tokenGet][user] = balances[tokenGet][user].add(amount.sub(tradeMakerFee));
        balances[tokenGet][feeAccount] = balances[tokenGet][feeAccount].add(amount.add(tradeTakerFee).add(tradeMakerFee));
        balances[tokenGive][user] = balances[tokenGive][user].sub(amountGive.mul(amount).div(amountGet));
        balances[tokenGive][msg.sender] = balances[tokenGive][msg.sender].add(amountGive.mul(amount).div(amountGet));
        fills[user][hash] = fills[user][hash].add(amount);
    }

    function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == addr;
    }
}
