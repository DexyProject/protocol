pragma solidity ^0.4.20;

import "./ExchangeInterface.sol";
import "./Libraries/SafeMath.sol";
import "./Vault/VaultInterface.sol";
import "./Tokens/ERC20.sol";
import "./Ownership/Ownable.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;

    enum SigMode {TYPED_SIG_EIP, GETH, TREZOR}

    struct Order {
        address user;
        address tokenGive;
        address tokenGet;
        uint amountGive;
        uint amountGet;
        uint expires;
        uint nonce;
    }

    bytes32 constant public HASH_SCHEME = keccak256(
        "address Token Get",
        "uint Amount Get",
        "address Token Give",
        "uint Amount Give",
        "uint Expires",
        "uint Nonce",
        "address User",
        "address Exchange"
    );

    uint256 constant public MAX_FEE = 5000000000000000; // 0.5%

    VaultInterface public vault;

    uint public takerFee = 0;
    address public feeAccount;

    mapping (address => mapping (bytes32 => uint)) fills;
    mapping (bytes32 => bool) cancelled;

    function Exchange(uint _takerFee, address _feeAccount, VaultInterface _vault) public {
        setFees(_takerFee);
        setFeeAccount(_feeAccount);
        vault = _vault;
    }

    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param amount Amount of the order to be filled.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    function trade(address[3] addresses, uint[4] values, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode) external {
        Order memory order = createOrder(addresses, values);

        require(msg.sender != order.user);
        bytes32 hash = orderHash(order);

        require(vault.balanceOf(order.tokenGet, msg.sender) >= amount);
        require(canTradeInternal(order, amount, v, r, s, mode, hash));

        performTrade(order, amount, hash);

        emit Traded(
            hash,
            order.tokenGive,
            order.amountGive * amount / order.amountGet,
            order.tokenGet,
            amount,
            order.user,
            msg.sender
        );
    }

    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    function cancel(address[3] addresses, uint[4] values) external {
        Order memory order = createOrder(addresses, values);

        require(msg.sender == order.user);
        require(order.amountGive > 0 && order.amountGet > 0);

        bytes32 hash = orderHash(order);
        require(fills[order.user][hash] < order.amountGet);
        require(!cancelled[hash]);

        cancelled[hash] = true;
        emit Cancelled(hash);
    }

    function setFees(uint _takerFee) public onlyOwner {
        require(_takerFee <= MAX_FEE);
        takerFee = _takerFee;
    }

    function setFeeAccount(address _feeAccount) public onlyOwner {
        require(_feeAccount != 0x0);
        feeAccount = _feeAccount;
    }

    function withdraw(address token, uint amount) public onlyOwner {
        if (token == 0x0) {
            msg.sender.transfer(amount);
            return;
        }

        ERC20(token).transfer(msg.sender, amount);
    }

    function filled(address user, bytes32 hash) public view returns (uint) {
        return fills[user][hash];
    }

    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param amount Amount of the order to be filled.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    /// @return Boolean if order can be traded
    function canTrade(address[3] addresses, uint[4] values, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode) public view returns (bool) {
        Order memory order = createOrder(addresses, values);

        bytes32 hash = orderHash(order);

        return canTradeInternal(order, amount, v, r, s, mode, hash);
    }

    function getVolume(uint amountGet, address tokenGive, uint amountGive, address user, bytes32 hash) public view returns (uint) {
        uint availableTaker = amountGet.sub(fills[user][hash]);
        uint availableMaker = vault.balanceOf(tokenGive, user).mul(amountGet).div(amountGive);

        return (availableTaker < availableMaker) ? availableTaker : availableMaker;
    }

    function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s, SigMode mode) public pure returns (bool) {
        if (mode == SigMode.GETH) {
            return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == addr;
        } else if (mode == SigMode.TREZOR) {
            return ecrecover(keccak256("\x19Ethereum Signed Message:\n\x20", hash), v, r, s) == addr;
        }

        return ecrecover(hash, v, r, s) == addr;
    }

    function performTrade(Order memory order, uint amount, bytes32 hash) internal {
        uint give = order.amountGive.mul(amount).div(order.amountGet);
        uint tradeTakerFee = give.mul(takerFee).div(1 ether);

        if (tradeTakerFee > 0) {
            vault.transfer(order.tokenGive, order.user, feeAccount, tradeTakerFee);
        }

        vault.transfer(order.tokenGet, msg.sender, order.user, amount);
        vault.transfer(order.tokenGive, order.user, msg.sender, give.sub(tradeTakerFee));

        fills[order.user][hash] = fills[order.user][hash].add(amount);
    }

    function canTradeInternal(Order memory order, uint amount, uint8 v, bytes32 r, bytes32 s, uint8 mode, bytes32 hash) internal view returns (bool) {
        if (!didSign(order.user, hash, v, r, s, SigMode(mode))) {
            return false;
        }

        if (cancelled[hash]) {
            return false;
        }

        if (getVolume(order.amountGet, order.tokenGive, order.amountGive, order.user, hash) < amount) {
            return false;
        }

        if (!vault.isApproved(order.user, this)) {
            return false;
        }

        if (order.expires <= now) {
            return false;
        }

        return fills[order.user][hash].add(amount) <= order.amountGet;
    }

    function orderHash(Order memory order) internal view returns (bytes32) {
        return keccak256(
            HASH_SCHEME,
            keccak256(order.tokenGet, order.amountGet, order.tokenGive, order.amountGive, order.expires, order.nonce, order.user, this)
        );
    }

    function createOrder(address[3] addresses, uint[4] values) internal pure returns (Order memory) {
        return Order({
            user: addresses[0],
            tokenGive: addresses[1],
            tokenGet: addresses[2],
            amountGive: values[0],
            amountGet: values[1],
            expires: values[2],
            nonce: values[3]
        });
    }
}
