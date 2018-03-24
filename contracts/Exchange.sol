pragma solidity ^0.4.18;

import "./ExchangeInterface.sol";
import "./Libraries/SafeMath.sol";
import "./Libraries/OrderLibrary.sol";
import "./Ownership/Ownable.sol";
import "./Tokens/ERC20.sol";

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;
    using OrderLibrary for OrderLibrary.Order;

    enum SigMode {TYPED_SIG_EIP, GETH, TREZOR}

    uint256 constant public MAX_FEE = 5000000000000000; // 0.5% ((0.5 / 100) * 10**18)

    VaultInterface public vault;

    uint public takerFee = 0;
    address public feeAccount;

    mapping (address => mapping (bytes32 => bool)) private orders;
    mapping (address => mapping (bytes32 => uint)) private fills;
    mapping (bytes32 => bool) private cancelled;

    function Exchange(uint _takerFee, address _feeAccount, VaultInterface _vault) public {
        require(address(_vault) != 0x0);
        setFees(_takerFee);
        setFeeAccount(_feeAccount);
        vault = _vault;
    }

    /// @dev Withdraws tokens accidentally sent to this contract.
    /// @param token Address of the token to withdraw.
    /// @param amount Amount of tokens to withdraw.
    function withdraw(address token, uint amount) external onlyOwner {
        if (token == 0x0) {
            msg.sender.transfer(amount);
            return;
        }

        ERC20(token).transfer(msg.sender, amount);
    }

    /// @dev Takes an order.
    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param fillAmount Amount of the order to be filled.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    function trade(address[3] addresses, uint[4] values, uint fillAmount, uint8 v, bytes32 r, bytes32 s, uint8 mode)
        external
    {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        require(msg.sender != order.user);
        bytes32 hash = order.hash();

        require(vault.balanceOf(order.tokenGet, msg.sender) >= fillAmount);
        require(canTrade(order, fillAmount, v, r, s, mode, hash));

        performTrade(order, fillAmount, hash);

        Traded(
            hash,
            order.tokenGive,
            order.amountGive * fillAmount / order.amountGet,
            order.tokenGet,
            fillAmount,
            order.user,
            msg.sender
        );
    }

    /// @dev Cancels an order.
    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    function cancel(address[3] addresses, uint[4] values) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        require(msg.sender == order.user);
        require(order.amountGive > 0 && order.amountGet > 0);

        bytes32 hash = order.hash();
        require(fills[order.user][hash] < order.amountGet);
        require(!cancelled[hash]);

        cancelled[hash] = true;
        Cancelled(hash);
    }

    /// @dev Creates an order which is then indexed in the orderbook.
    /// @param addresses Array of trade's tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    function order(address[2] addresses, uint[4] values) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder([msg.sender, addresses[0], addresses[1]], values);

        require(vault.isApproved(order.user, this));
        require(vault.balanceOf(order.tokenGive, order.user) >= order.amountGive);

        bytes32 hash = order.hash();

        require(!orders[msg.sender][hash]);
        orders[msg.sender][hash] = true;

        Ordered(
            order.user,
            order.tokenGive,
            order.tokenGet,
            order.amountGive,
            order.amountGet,
            order.expires,
            order.nonce
        );
    }

    /// @dev Checks if a order can be traded.
    /// @param addresses Array of trade's user, tokenGive and tokenGet.
    /// @param values Array of trade's amountGive, amountGet, expires and nonce.
    /// @param fillAmount Amount of the order to be filled.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    /// @return Boolean if order can be traded
    function canTrade(address[3] addresses, uint[4] values, uint fillAmount, uint8 v, bytes32 r, bytes32 s, uint8 mode)
        external
        view
        returns (bool)
    {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        bytes32 hash = order.hash();

        return canTrade(order, fillAmount, v, r, s, mode, hash);
    }

    /// @dev Returns how much of an order was filled.
    /// @param user User who created the order.
    /// @param hash Hash of the order.
    /// @return Amount which was filled.
    function filled(address user, bytes32 hash) external view returns (uint) {
        return fills[user][hash];
    }

    /// @dev Sets the taker fee.
    /// @param _takerFee New taker fee.
    function setFees(uint _takerFee) public onlyOwner {
        require(_takerFee <= MAX_FEE);
        takerFee = _takerFee;
    }

    /// @dev Sets the account where fees will be transferred to.
    /// @param _feeAccount Address for the account.
    function setFeeAccount(address _feeAccount) public onlyOwner {
        require(_feeAccount != 0x0);
        feeAccount = _feeAccount;
    }

    function vault() public view returns (VaultInterface) {
        return vault;
    }

    /// @dev Checks if an order was created on chain.
    /// @param user User who created the order.
    /// @param hash Hash of the order.
    /// @return Boolean if the order was created on chain.
    function isOrdered(address user, bytes32 hash) public view returns (bool) {
        return orders[user][hash];
    }

    /// @dev Checks if a given signature was signed by a signer.
    /// @param signer Address of the signer.
    /// @param hash Hash which was signed.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    /// @return Boolean if the hash was signed by the signer.
    function isValidSignature(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s, SigMode mode)
        public
        pure
        returns (bool)
    {
        if (mode == SigMode.GETH) {
            hash = keccak256("\x19Ethereum Signed Message:\n32", hash);
        } else if (mode == SigMode.TREZOR) {
            hash = keccak256("\x19Ethereum Signed Message:\n\x20", hash);
        }

        return ecrecover(hash, v, r, s) == signer;
    }

    /// @dev Executes the actual trade by transferring balances.
    /// @param order Order to be traded.
    /// @param fillAmount Amount to be traded.
    /// @param hash Hash of the order.
    function performTrade(OrderLibrary.Order memory order, uint fillAmount, bytes32 hash) internal {
        uint give = order.amountGive.mul(fillAmount).div(order.amountGet);
        uint tradeTakerFee = give.mul(takerFee).div(1 ether);

        if (tradeTakerFee > 0) {
            vault.transfer(order.tokenGive, order.user, feeAccount, tradeTakerFee);
        }

        vault.transfer(order.tokenGet, msg.sender, order.user, fillAmount);
        vault.transfer(order.tokenGive, order.user, msg.sender, give.sub(tradeTakerFee));

        fills[order.user][hash] = fills[order.user][hash].add(fillAmount);
    }

    /// @dev Indicates whether or not an certain amount of an order can be traded.
    /// @param order Order to be traded.
    /// @param fillAmount Desired amount to be traded.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @param mode Signature mode used. (0 = Typed Signature, 1 = Geth standard, 2 = Trezor)
    /// @param hash Hash of the order.
    /// @return Boolean if order can be traded
    function canTrade(OrderLibrary.Order memory order, uint fillAmount, uint8 v, bytes32 r, bytes32 s, uint8 mode, bytes32 hash)
        internal
        view
        returns (bool)
    {
        // if the order has never been traded against, we need to check the sig.
        if (fills[order.user][hash] == 0) {
            // ensures order was either created on chain, or signature is valid
            if (!isOrdered(order.user, hash) && !isValidSignature(order.user, hash, v, r, s, SigMode(mode))) {
                return false;
            }
        }

        if (cancelled[hash]) {
            return false;
        }

        // fillAmount + filled amount will not exceed order amount.
        if (fills[order.user][hash].add(fillAmount) > order.amountGet) {
            return false;
        }

        // ensure user has enough balance to fill order
        if (vault.balanceOf(order.tokenGive, order.user).mul(order.amountGet).div(order.amountGive) < fillAmount) {
            return false;
        }

        if (!vault.isApproved(order.user, this)) {
            return false;
        }

        return order.expires > now;
    }
}
