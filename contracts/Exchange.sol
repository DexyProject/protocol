pragma solidity ^0.4.21;

import "./ExchangeInterface.sol";
import "./Libraries/OrderLibrary.sol";
import "./Libraries/TradeLibrary.sol";
import "./Ownership/Ownable.sol";
import "./Tokens/ERC20.sol";

contract Exchange is Ownable, ExchangeInterface {

    using OrderLibrary for OrderLibrary.Order;
    using TradeLibrary for TradeLibrary.Exchange;

    address constant public ETH = 0x0;

    uint256 constant public MAX_FEE = 5000000000000000; // 0.5% ((0.5 / 100) * 10**18)

    TradeLibrary.Exchange public exchange;

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
    /// @param addresses Array of trade's maker, makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @param signature Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    function trade(address[3] addresses, uint[4] values, bytes signature, uint maxFillAmount) external {
        exchange.trade(OrderLibrary.createOrder(addresses, values), msg.sender, signature, maxFillAmount);
    }

    /// @dev Cancels an order.
    /// @param addresses Array of trade's maker, makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    function cancel(address[3] addresses, uint[4] values) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        require(msg.sender == order.maker);
        require(order.makerTokenAmount > 0 && order.takerTokenAmount > 0);

        bytes32 hash = order.hash();
        require(exchange.fills[hash] < order.takerTokenAmount);
        require(!exchange.cancelled[hash]);

        exchange.cancelled[hash] = true;
        emit Cancelled(hash);
    }

    /// @dev Creates an order which is then indexed in the orderbook.
    /// @param addresses Array of trade's makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    function order(address[2] addresses, uint[4] values) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(
            [msg.sender, addresses[0], addresses[1]],
            values
        );

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
    /// @param addresses Array of trade's maker, makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @param signature Signed order along with signature mode.
    /// @return Boolean if order can be traded
    function canTrade(address[3] addresses, uint[4] values, bytes signature)
        external
        view
        returns (bool)
    {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);
        return exchange.canTrade(order, signature, order.hash());
    }

    /// @dev Returns if user has subscribed to trade hooks.
    /// @param subscriber Address of the subscriber.
    /// @return Boolean if user is subscribed.
    function isSubscribed(address subscriber) external view returns (bool) {
        return exchange.subscribed[subscriber];
    }

    /// @dev Checks how much of an order can be filled.
    /// @param addresses Array of trade's maker, makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @return Amount of the order which can be filled.
    function availableAmount(address[3] addresses, uint[4] values) external view returns (uint) {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);
        return exchange.availableAmount(order, order.hash());
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
        return exchange.orders[user][hash];
    }
}
