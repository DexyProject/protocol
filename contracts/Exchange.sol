pragma solidity ^0.4.21;

import "./ExchangeInterface.sol";
import "./Libraries/OrderLibrary.sol";
import "./Libraries/ExchangeLibrary.sol";
import "./Ownership/Ownable.sol";
import "./Tokens/ERC20.sol";

contract Exchange is Ownable, ExchangeInterface {

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


    function multifillUpTo(address makerToken, address takerToken, address[] makers, uint[] values, bytes32[] sigmain, uint16[] sigaux, uint maxFillAmount) external {
        require(makers.length == sigaux.length);
        require(makers.length*2 == sigmain.length);
        require(makers.length*4 == values.length);

        address[3] memory addrs;
        uint[4] memory vals;
        bytes memory s;
        uint filledSoFar = 0;

        for (uint i = 0; i < makers.length; i++){
            for (uint j = 0; j < 4; j++){
                vals[j] = values[i*4 + j];
            }
            addrs[0] = makers[i];
            addrs[1] = makerToken;
            addrs[2] = takerToken;
            s = sigArrayToBytes(sigmain, sigaux, i);
            uint filled = exchange.trade(OrderLibrary.createOrder(addrs, vals), msg.sender, s, maxFillAmount-filledSoFar);
            filledSoFar = filledSoFar + filled;
            if (filledSoFar >= maxFillAmount){
                return;
            }
        }
    }


    function multitrade(address[] addresses, uint[] values, bytes32[] sigmain, uint16[] sigaux, uint[] maxFillAmount) external {
        require(addresses.length == 3*sigaux.length);
        require(values.length == 4*sigaux.length);
        require(sigmain.length == 2*sigaux.length);
        require(maxFillAmount.length == sigaux.length);

        address[3] memory addrs;
        uint[4] memory vals;
        bytes memory s;

        for (uint i = 0; i < sigaux.length; i++){
            for (uint j = 0; j < 3; j++){
                addrs[j] = addresses[(i*3)+j];
            }
            for (j = 0; j < 4; j++){
                vals[j] = values[(i*4)+j];
            }
            s = sigArrayToBytes(sigmain, sigaux, i);
            exchange.trade(OrderLibrary.createOrder(addrs, vals), msg.sender, s, maxFillAmount[i]);
        }
    }

    /// @dev Takes an order.
    /// @param addresses Array of trade's maker, makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @param signature Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    function trade(address[3] addresses, uint[4] values, bytes signature, uint maxFillAmount) external returns (uint) {
        return exchange.trade(OrderLibrary.createOrder(addresses, values), msg.sender, signature, maxFillAmount);
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

    function sigArrayToBytes(bytes32[] sm, uint16[] sa, uint i) internal pure returns (bytes) {
            bytes32 s1 = sm[i*2];
            bytes32 s2 = sm[i*2 + 1];
            uint16 s3 = sa[i];
            uint8 s4 = uint8(s3 % 256);
            s3 = (s3 - uint16(s4)) / 256;
            bytes memory s = new bytes(66);
            assembly {
                mstore(add(s, 32), s1)
                mstore(add(s, 64), s2)
                mstore8(add(s, 96), s3)
                mstore8(add(s, 97), s4)
            }
    }
}
