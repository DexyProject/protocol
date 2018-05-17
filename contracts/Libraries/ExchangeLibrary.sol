pragma solidity ^0.4.23;

import "./OrderLibrary.sol";
import "./SafeMath.sol";
import "@dexyproject/signature-validator/contracts/SignatureValidator.sol";
import "./../Vault/VaultInterface.sol";
import "./../HookSubscriber.sol";
import "./../Fees/FeeInterface.sol";

library ExchangeLibrary {

    using SafeMath for *;
    using OrderLibrary for OrderLibrary.Order;
    using ExchangeLibrary for ExchangeLibrary.Exchange;

    event Traded(
        bytes32 indexed hash,
        address makerToken,
        uint makerTokenAmount,
        address takerToken,
        uint takerTokenAmount,
        address maker,
        address taker
    );

    struct Exchange {
        VaultInterface vault;
        FeeInterface feeManager;
        address feeAccount;
        mapping (address => mapping (bytes32 => bool)) orders;
        mapping (bytes32 => uint) fills;
        mapping (bytes32 => bool) cancelled;
        mapping (address => bool) subscribed;
    }

    uint256 constant private MAX_ROUNDING_PERCENTAGE = 1000; // 0.1%
    uint256 constant private MAX_HOOK_GAS = 40000; // enough for a storage write and some accounting logic

    /// @dev Executes the actual trade by transferring balances.
    /// @param self Exchange storage.
    /// @param order Order to be traded.
    /// @param taker Address of the taker.
    /// @param signature Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    function trade(
        Exchange storage self,
        OrderLibrary.Order memory order,
        address taker,
        bytes signature,
        uint maxFillAmount
    )
        internal
    {
        require(taker != order.maker);
        bytes32 hash = order.hash();

        require(order.makerToken != order.takerToken);
        require(canTrade(self, order, signature, hash));

        uint fillAmount = SafeMath.min256(maxFillAmount, availableAmount(self, order, hash));

        require(roundingPercent(fillAmount, order.takerTokenAmount, order.makerTokenAmount) <= MAX_ROUNDING_PERCENTAGE);
        require(self.vault.balanceOf(order.takerToken, taker) >= fillAmount);

        uint tradeTakerFee = self.calculateFee(
            order.makerTokenAmount.mul(fillAmount).div(order.takerTokenAmount),
            taker
        );

        if (tradeTakerFee > 0) {
            self.vault.transfer(order.makerToken, order.maker, self.feeAccount, tradeTakerFee);
        }

        self.vault.transfer(order.takerToken, taker, order.maker, fillAmount);
        self.vault.transfer(order.makerToken, order.maker, taker, makeAmount.sub(tradeTakerFee));

        self.fills[hash] = self.fills[hash].add(fillAmount);
        assert(self.fills[hash] <= order.takerTokenAmount);

        if (self.subscribed[order.maker]) {
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
            taker
        );
    }

    /// @dev Indicates whether or not an certain amount of an order can be traded.
    /// @param self Exchange storage.
    /// @param order Order to be traded.
    /// @param signature Signed order along with signature mode.
    /// @param hash Hash of the order.
    /// @return Boolean if order can be traded
    function canTrade(Exchange storage self, OrderLibrary.Order memory order, bytes signature, bytes32 hash)
        internal
        view
        returns (bool)
    {
        // if the order has never been traded against, we need to check the sig.
        if (self.fills[hash] == 0) {
            // ensures order was either created on chain, or signature is valid
            if (!self.orders[order.maker][hash] && !SignatureValidator.isValidSignature(hash, order.maker, signature)) {
                return false;
            }
        }

        if (self.cancelled[hash]) {
            return false;
        }

        if (!self.vault.isApproved(order.maker, this)) {
            return false;
        }

        if (order.takerTokenAmount == 0) {
            return false;
        }

        if (order.makerTokenAmount == 0) {
            return false;
        }

        // ensures that the order still has an available amount to be filled.
        if (availableAmount(self, order, hash) == 0) {
            return false;
        }

        return order.expires > now;
    }

    /// @dev Returns the maximum available amount that can be taken of an order.
    /// @param self Exchange storage.
    /// @param order Order to check.
    /// @param hash Hash of the order.
    /// @return Amount of the order that can be filled.
    function availableAmount(Exchange storage self, OrderLibrary.Order memory order, bytes32 hash)
        internal
        view
        returns (uint)
    {
        return SafeMath.min256(
            order.takerTokenAmount.sub(self.fills[hash]),
            self.vault.balanceOf(order.makerToken, order.maker).mul(order.takerTokenAmount).div(order.makerTokenAmount)
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

    /// @dev Returns the fee for a specific amount.
    /// @param self Exchange storage.
    /// @param takeAmount Amount of order to be taken.
    /// @param taker Address of the taker.
    /// @return Fee amount.
    function calculateFee(Exchange storage self, uint takeAmount, address taker) internal view returns (uint) {
        uint feeAmount = self.feeManager.fees(taker);
        if (feeAmount == 0) {
            return 0;
        }

        return takeAmount.mul(feeAmount).div(1 ether);
    }
}
