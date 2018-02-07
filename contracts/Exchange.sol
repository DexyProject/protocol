pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./SafeMath.sol";
import "./Vault/VaultInterface.sol";
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

    VaultInterface public vault;

    uint makerFee = 0;
    uint takerFee = 0;
    address feeAccount;

    mapping (address => mapping (bytes32 => uint)) fills;
    mapping (bytes32 => bool) cancelled;

    function Exchange(VaultInterface _vault) public {
        vault = _vault;
    }

    function () public payable {
        revert();
    }

    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param amount Amount of the order to be filled.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    function trade(address[3] addresses, uint[4] values, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode) external {
        Order memory order = Order({
            user: addresses[0],
            tokenGive: addresses[1],
            tokenGet: addresses[2],
            amountGive: values[0],
            amountGet: values[1],
            expires: values[2],
            nonce: values[3]
        });

        require(msg.sender != order.user);
        bytes32 hash = orderHash(order);

        require(vault.balanceOf(order.tokenGet,msg.sender) >= amount);
        require(canTradeInternal(order, v, r, s, amount, mode, hash));

        performTrade(order.tokenGet, order.amountGet, order.tokenGive, order.amountGive, order.user, amount, hash);
    }

    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    function cancel(address[3] addresses, uint[4] values, uint8 v, bytes32 r, bytes32 s, uint mode) external {
        Order memory order = Order({
            user: addresses[0],
            tokenGive: addresses[1],
            tokenGet: addresses[2],
            amountGive: values[0],
            amountGet: values[1],
            expires: values[2],
            nonce: values[3]
        });

        require(msg.sender != order.user);
        require(order.amountGive > 0 && order.amountGet > 0);

        bytes32 hash = orderHash(order);
        require(didSign(msg.sender, hash, v, r, s, SigMode(mode)));

        cancelled[hash] = true;
        Cancelled(hash);
    }

    function setFees(uint _makerFee, uint _takerFee) public onlyOwner {
        makerFee = _makerFee;
        takerFee = _takerFee;
    }

    function setFeeAccount(address _feeAccount) public onlyOwner {
        feeAccount = _feeAccount;
    }

    function filled(address user, bytes32 hash) public view returns (uint) {
        return fills[user][hash];
    }

    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param amount Amount of the order to be filled.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    /// @return Boolean if order can be traded
    function canTrade(address[3] addresses, uint[4] values, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode) public view returns (bool) {
        Order memory order = Order({
            user: addresses[0],
            tokenGive: addresses[1],
            tokenGet: addresses[2],
            amountGive: values[0],
            amountGet: values[1],
            expires: values[2],
            nonce: values[3]
        });

        bytes32 hash = orderHash(order);

        return canTradeInternal(order, v, r, s, amount, mode, hash);
    }

    function getVolume(uint amountGet, address tokenGive, uint amountGive, address user, bytes32 hash) public view returns (uint) {
        uint availableTaker = amountGet.sub(fills[user][hash]);
        uint availableMaker = vault.balanceOf(tokenGive, user).mul(amountGet).div(amountGive);

        return (availableTaker < availableMaker) ? availableTaker : availableMaker;
    }

    function canTradeInternal(Order order, uint8 v, bytes32 r, bytes32 s, uint amount, uint mode, bytes32 hash) internal view returns (bool) {
        if (!didSign(order.user, hash, v, r, s, SigMode(mode))) {
            return false;
        }

        if (cancelled[hash]) {
            return false;
        }

        if (getVolume(order.amountGet, order.tokenGive, order.amountGive, order.user, hash) < amount) {
            return false;
        }

        return order.expires > now && fills[order.user][hash].add(amount) <= order.amountGet;
    }

    function performTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount, bytes32 hash) internal {
        uint tradeTakerFee = amount.mul(takerFee).div(1 ether);

        vault.transfer(tokenGet, msg.sender, user, amount);
        vault.transfer(tokenGive, user, msg.sender, amountGive.mul(amount).div(amountGet));

        vault.transfer(tokenGet, msg.sender, feeAccount, tradeTakerFee);
        vault.transfer(tokenGet, user, feeAccount, tradeTakerFee);

        fills[user][hash] = fills[user][hash].add(amount);
    }

    function orderHash(Order order) internal view returns (bytes32) {
        return keccak256(
            HASH_SCHEME,
            keccak256(order.tokenGet, order.amountGet, order.tokenGive, order.amountGive, order.expires, order.nonce, order.user, this)
        );
    }

    function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s, SigMode mode) internal pure returns (bool) {
        if (mode == SigMode.GETH) {
            return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == addr;
        } else if (mode == SigMode.TREZOR) {
            return ecrecover(keccak256("\x19Ethereum Signed Message:\n\x20", hash), v, r, s) == addr;
        }

        return ecrecover(hash, v, r, s) == addr;
    }
}
