pragma solidity ^0.4.21;
pragma experimental ABIEncoderV2;

import "./Libraries/SafeMath.sol";
import "./Libraries/SignatureValidator.sol";
import "./ExchangeInterface.sol";
import "./Libraries/OrderLibrary.sol";
import "./Libraries/ExchangeLibrary.sol";
import "./Ownership/Ownable.sol";
import "./Tokens/ERC20.sol";

contract Exchange is Ownable {

    using OrderLibrary for OrderLibrary.Order;
    using ExchangeLibrary for ExchangeLibrary.Exchange;

    address constant public ETH = 0x0;

    uint256 constant public MAX_FEE = 5000000000000000; // 0.5% ((0.5 / 100) * 10**18)

    ExchangeLibrary.Exchange public exchange;

    function Exchange(uint _takerFee, address _feeAccount, VaultInterface _vault) public {
        require(address(_vault) != 0x0);
        setFees(_takerFee);
        setFeeAccount(_feeAccount);
        exchange.vault = _vault;
    }

    /// @dev Withdraws tokens accidentally sent to this contract.
    /// @param token Address of the token to withdraw.
    /// @param amount Amount of tokens to withdraw.
    function withdraw(address token, uint amount) external onlyOwner {
        if (token == ETH) {
            msg.sender.transfer(amount);
            return;
        }

        ERC20(token).transfer(msg.sender, amount);
    }

    /// @dev Subscribes user to trade hooks.
    function subscribe() external {
        require(!exchange.subscribed[msg.sender]);
        exchange.subscribed[msg.sender] = true;
        emit Subscribed(msg.sender);
    }

    /// @dev Unsubscribes user from trade hooks.
    function unsubscribe() external {
        require(exchange.subscribed[msg.sender]);
        exchange.subscribed[msg.sender] = false;
        emit Unsubscribed(msg.sender);
    }

    /// @dev Takes an order.
    /// @param order Order to take.
    /// @param signature Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    function trade(OrderLibrary.Order order, bytes signature, uint maxFillAmount) external {
        require(msg.sender != order.maker);
        bytes32 hash = order.hash();

        require(order.makerToken != order.takerToken);
        require(canTrade(order, signature, hash));

        uint fillAmount = SafeMath.min256(maxFillAmount, availableAmount(order, hash));

        require(roundingPercent(fillAmount, order.takerTokenAmount, order.makerTokenAmount) <= MAX_ROUNDING_PERCENTAGE);
        require(vault.balanceOf(order.takerToken, msg.sender) >= fillAmount);

        uint makeAmount = order.makerTokenAmount.mul(fillAmount).div(order.takerTokenAmount);
        uint tradeTakerFee = makeAmount.mul(takerFee).div(1 ether);

        if (tradeTakerFee > 0) {
            vault.transfer(order.makerToken, order.maker, feeAccount, tradeTakerFee);
        }

        vault.transfer(order.takerToken, msg.sender, order.maker, fillAmount);
        vault.transfer(order.makerToken, order.maker, msg.sender, makeAmount.sub(tradeTakerFee));

        fills[hash] = fills[hash].add(fillAmount);
        assert(fills[hash] <= order.takerTokenAmount);

        if (subscribed[order.maker]) {
            order.maker.call.gas(MAX_HOOK_GAS)(
                HookSubscriber(order.maker).tradeExecuted.selector,
                order.takerToken,
                fillAmount
            );
        }

        emit Traded(
            hash,
            order.makerToken,
            makeAmount,
            order.takerToken,
            fillAmount,
            order.maker,
            msg.sender
        );
    }

    /// @dev Cancels an order.
    /// @param order Order struct for the cancelling order.
    function cancel(OrderLibrary.Order order) external {
        require(msg.sender == order.maker);
        require(order.makerTokenAmount > 0 && order.takerTokenAmount > 0);

        bytes32 hash = order.hash();
        require(exchange.fills[hash] < order.takerTokenAmount);
        require(!exchange.cancelled[hash]);

        exchange.cancelled[hash] = true;
        emit Cancelled(hash);
    }

    /// @dev Creates an order which is then indexed in the orderbook.
    /// @param order Order to create.
    function order(OrderLibrary.Order order) external {
        order.maker = msg.sender;

        require(exchange.vault.isApproved(order.maker, this));
        require(exchange.vault.balanceOf(order.makerToken, order.maker) >= order.makerTokenAmount);
        require(order.makerToken != order.takerToken);
        require(order.makerTokenAmount > 0);
        require(order.takerTokenAmount > 0);

        bytes32 hash = order.hash();

        require(!exchange.orders[msg.sender][hash]);
        exchange.orders[msg.sender][hash] = true;

        emit Ordered(
            order.maker,
            order.makerToken,
            order.takerToken,
            order.makerTokenAmount,
            order.takerTokenAmount,
            order.expires,
            order.nonce
        );
    }

    /// @dev Checks if a order can be traded.
    /// @param order Order to check.
    /// @param signature Signed order along with signature mode.
    /// @return Boolean if order can be traded
    function canTrade(OrderLibrary.Order order, bytes signature) external view returns (bool) {
        bytes32 hash = order.hash();
        return canTrade(order, signature, hash);
    }

    /// @dev Returns if user has subscribed to trade hooks.
    /// @param subscriber Address of the subscriber.
    /// @return Boolean if user is subscribed.
    function isSubscribed(address subscriber) external view returns (bool) {
        return exchange.subscribed[subscriber];
    }

    /// @dev Checks how much of an order can be filled.
    /// @param order Order to check.
    /// @return Amount of the order which can be filled.
    function availableAmount(OrderLibrary.Order order) external view returns (uint) {
        return availableAmount(order, order.hash());
    }

    /// @dev Returns how much of an order was filled.
    /// @param hash Hash of the order.
    /// @return Amount which was filled.
    function filled(bytes32 hash) external view returns (uint) {
        return exchange.fills[hash];
    }

    /// @dev Sets the taker fee.
    /// @param _takerFee New taker fee.
    function setFees(uint _takerFee) public onlyOwner {
        require(_takerFee <= MAX_FEE);
        exchange.takerFee = _takerFee;
    }

    /// @dev Sets the account where fees will be transferred to.
    /// @param _feeAccount Address for the account.
    function setFeeAccount(address _feeAccount) public onlyOwner {
        require(_feeAccount != 0x0);
        exchange.feeAccount = _feeAccount;
    }

    function vault() public view returns (VaultInterface) {
        return exchange.vault;
    }

    /// @dev Checks if an order was created on chain.
    /// @param user User who created the order.
    /// @param hash Hash of the order.
    /// @return Boolean if the order was created on chain.
    function isOrdered(address user, bytes32 hash) public view returns (bool) {
        return orders[user][hash];
    }

    /// @dev Indicates whether or not an certain amount of an order can be traded.
    /// @param order Order to be traded.
    /// @param signature Signed order along with signature mode.
    /// @param hash Hash of the order.
    /// @return Boolean if order can be traded
    function canTrade(OrderLibrary.Order memory order, bytes signature, bytes32 hash)
        internal
        view
        returns (bool)
    {
        // if the order has never been traded against, we need to check the sig.
        if (fills[hash] == 0) {
            // ensures order was either created on chain, or signature is valid
            if (!isOrdered(order.maker, hash) && !SignatureValidator.isValidSignature(hash, order.maker, signature)) {
                return false;
            }
        }

        if (cancelled[hash]) {
            return false;
        }

        if (!vault.isApproved(order.maker, this)) {
            return false;
        }

        if (order.takerTokenAmount == 0) {
            return false;
        }

        if (order.makerTokenAmount == 0) {
            return false;
        }

        // ensures that the order still has an available amount to be filled.
        if (availableAmount(order, hash) == 0) {
            return false;
        }

        return order.expires > now;
    }

    /// @dev Returns the maximum available amount that can be taken of an order.
    /// @param order Order to check.
    /// @param hash Hash of the order.
    /// @return Amount of the order that can be filled.
    function availableAmount(OrderLibrary.Order memory order, bytes32 hash) internal view returns (uint) {
        return SafeMath.min256(
            order.takerTokenAmount.sub(fills[hash]),
            vault.balanceOf(order.makerToken, order.maker).mul(order.takerTokenAmount).div(order.makerTokenAmount)
        );
    }

    /// @dev Returns the percentage which was rounded when dividing.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with.
    /// @return Percentage rounded.
    function roundingPercent(uint numerator, uint denominator, uint target) internal pure returns (uint) {
        // Inspired by https://github.com/0xProject/contracts/blob/1.0.0/contracts/Exchange.sol#L472-L490
        uint remainder = mulmod(target, numerator, denominator);
        if (remainder == 0) {
            return 0;
        }

        return remainder.mul(1000000).div(numerator.mul(target));
    }
}
