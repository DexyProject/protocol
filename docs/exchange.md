DEXY Exchange Overview
---

DEXY is a decentralized exchange backed by smart contracts.

API
===

The DEXY exchange implements the interface specified in [ExchangeInterface.sol](/contracts/ExchangeInterface.sol):


```Solidity
function trade(address[3] addresses, uint[4] values, uint fillAmount, bytes signature) external;

function cancel(address[3] addresses, uint[4] values) external;

function order(address[2] addresses, uint[4] values) external;

function canTrade(address[3] addresses, uint[4] values, uint fillAmount, bytes signature)
    external
    view
    returns (bool);

function filled(address user, bytes32 hash) external view returns (uint);

function isOrdered(address user, bytes32 hash) public view returns (bool);

function vault() public view returns (VaultInterface);
```

Orders and Trades
===

The main functions users will interact with will be `order` and `trade`.

Trades are made against orders, and the order struct is defined as follows:

```Solidity
struct Order {
    address user;
    address makerToken;
    address tokenGet;
    uint amountGive;
    uint amountGet;
    uint expires;
    uint nonce;
}
```

From the struct definition above, we see an order includes:

* the address of the user,
* the address of the token they're selling (SELL),
* the address of the token they wish to buy (BUY),
* the amount they wish to sell for the SELL token,
* the amount they wish to receive of the BUY token,
* an expiration date after which the order can no longer execute,
* a nonce so that the order cannot be replayed

The price of the token being sold is then amountGive/amountGet, using makerToken as the base.

So, for example, if I'm buying TKN for ETH, then amountGive would be
denominated in ETH, and amountGet would be in TKN. If I offer 1 ETH for 10 TKN,
the price of TKN is then 1/10 or 0.1 ETH.

Executing Trades
===

There are two ways to trade against an order:

* Give an order as an argument when calling `trade()`, and with the order you
must supply a hash *signed* by the counterparty - either gotten from the order
book, or in some other off-chain manner
* Trade against an order that was already submitted to the Exchange contract
through `order()` - where entry additions are restricted to `msg.sender`

The reason for the restriction in case #2 such that no one can submit an order
on behalf of someone else, since `order` does not take a signature as an
argument. It also allows smart contracts to place orders on tokens they own, as
they would otherwise be unable to since smart contracts cannot sign since they
do not own private keys.


The system allows for partial fills, such that if there's an order registered
in the contract selling TKN for ETH, with the following parameters:


```
Order = {
  user = 0x123...,
  makerToken = TKN,
  tokenGet = ETH,
  amountGive = 1,
  amountGet = 10,
  expires = ...,
  nonce = 1
}
```

Then trader A can submit a trade with:

`trade(Order, 0.5, ...)`

and trader B can also submit a trade with:

`trade(Order, 0.5, ...)`

And both will be able to fill against the same order.

After both those trades are executed, the `fills` map for that order will equal
`amountGet` so no more trades will be able to complete against the order.

