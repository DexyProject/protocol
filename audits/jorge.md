# Dexy contracts code review – Jorge Izquierdo

## Introduction

- I reviewed the code at the following commit hash [ 4a0197fe327a002b45b3081241aaac86f1abcbff](https://github.com/DexyProject/contracts/tree/4a0197fe327a002b45b3081241aaac86f1abcbff).
- I received no compensation for the following review nor I'm financially
involved with Dexy in any capacity.
- I did this review as an individual, there is no formal relationship between
Aragon and Dexy.
- This is not a comprehensive review, just a check to see if I could put my own
money for trading in Dexy.
- I'm not a professional code auditor and I employed less than three hours in
total to review, communicate with the team about it and produce this report.
Don't take it too seriously.
- No guarantees and all the legal boring stuff. If something breaks and people lose money, they should go tweet [Dean](https://twitter.com/DeanEigenmann).
- A checksum of this file will be sent in the transaction data of a 0 value
transfer to the 0th account made with my verified account
`0x4838eab6f43841e0d233db4cea47bd64f614f0c5`
[Proof](https://etherscan.io/tx/0x5aaeb2d0361dbdf3b4ecadad1b49c239eb1b3b5e1cf973f6a4597ad56edc47b9). For obvious inception reasons the transaction hash of that
cannot be pasted here, but will be provided in parallel.

## TLDR

- I did not find any issues that could lead to losing or stealing funds under normal operation and the main exchange logic seems to check out.
- I feel safe about trading with my own money in the exchange.
- There is a high severity issue that would allow the exchange operator to steal
the entire token amount a taker thinks she's getting. On fixing, this is a
completely trustless exchange.
- Because of its design Dexy will provide the best UX in the (DEX) game.
- Please increase test coverage.

## Review

### Smart contract code

#### Critical severity

No critical issues were found.

#### High severity

##### Exchange operator can steal from taker by frontrunning a trade transaction with a `Exchange.setFees(...)` transaction
- https://github.com/DexyProject/contracts/blob/4a0197fe327a002b45b3081241aaac86f1abcbff/contracts/Exchange.sol#L201
- Because fees are not part of the orders themselves but just taken from a
storage value set by the operator, the operator can change the fee to a very
big amount right before a trade is mined, effectively allowing them to get the
entire amount they are taking.
- I suggest allowing the trader to pass the `takerFee` they are willing
to pay to `trade(...)` or adding a hardcoded max fee to the exchange code (say
5%).

#### Medium severity

##### Fee math bug requires taker to have an extra balance to pay for fees
- https://github.com/DexyProject/contracts/blob/development/contracts/Exchange.sol#L206

- I recommend just changing `give` for `give.sub(tradeTakerFee)`

#### Low severity

##### Vault balance check for transfers is too implicit
- At the moment, a trade will fail if the maker or taker don't have enough
balance because of the implicit underflow check in SafeMath.
- Even though I cannot think of any way to exploit this, it would be more future
proof to at least add a comment or assertion on this.

##### `withdrawOverflow(...)` does not support `ERC777.send(...)`
- Potentially low risk as the transfer method is backwards compatible.
- If the operator is a contract by adding this, the contract could get a callback
when an overflow is withdrawn.

#### Comments

##### `setERC777(...)` can be replaced by a standard interface check
- Rather than having an in-contract mapping of whether a token is ERC777 or not,
that fact can be checked by asserting whether a given token address has been
registered as ERC777 (From EIP: `The token-contract MUST register the ERC777Token interface via EIP-820.`)
- As far as I know, ERC777 is going to start using ERC780 rather than ERC820 for
this purpose so it might be a good idea to wait.
- After the first check to the token, it can safely be assumed the token won't
change its nature, and that value can be cached, saving 1 call in every
interaction.
- It is already done when receiving a callback from the token, so this might
be innecesary.

##### Upgrading to new Exchange version requires explicit transaction to Vault
- It should be possible for users to provide a message signing their approval
to migrate to the new version executing a trade.
- Anyone, including the Exchange, could then provide the signed message to the
Vault effectively approving a new version.
- This would allow to upgrade and start trading in just one transaction.

##### Wash trading 'protection' can give fake security to users - https://github.com/DexyProject/contracts/blob/4a0197fe327a002b45b3081241aaac86f1abcbff/contracts/Exchange.sol#L73

- It checks whether a user is not trading with themselves.
- Given that there is no sybil protection a user can create another account and
trade with themselves that way, which is impossible to detect.
- I suggest removing the check.

##### Cancels can be made much cheaper by scoping them by account
- https://github.com/DexyProject/contracts/blob/4a0197fe327a002b45b3081241aaac86f1abcbff/contracts/Exchange.sol#L112

- If rather than `mapping (bytes32 => bool) cancelled` the cancels mapping is
made `mapping (address => mapping (bytes32 => bool)) cancelled` no checks are
required to cancel an order, because a user can cancel order hashes in their
account even if they haven't signed the order to begin with.
- I consider this extremely important because there is a big incentive to
frontrun order cancels, so they should be as cheap as possible so the sender can
pay a higher gas price if needed.

##### Smart contracts cannot order make
- Order making requires an ECDSA signature which contracts cannot do.
- I recommend adding something similar like
[this](https://github.com/0xProject/ZEIPs/issues/7#issuecomment-355280219) but
with ERC780.


##### Fallback function is redundant
- https://github.com/DexyProject/contracts/blob/development/contracts/Exchange.sol#L51
- Solidity already generates code to revert if no function signature matches.
- If it is there to make the code more explicit it could be commented out.

##### Deposit and `trade(...)` could be made in just one transaction
- If the taker doesn't have enough balance in the Vault to make a trade, it
should try to deposit the required token amount into the user account and then
execute the trade.
- This could also be used as an implicit approval of the current exchange
instance.

#### Praise
- Great use of [ERC721 `eth_signTypedData`](https://github.com/ethereum/EIPs/pull/712) 🔏
- [ERC777 token](https://github.com/ethereum/EIPs/issues/777) support for deposits 🤩
- Great balance between convenience and security in the upgradeabily approach to
such a critical contract. 🕵️‍♀️
- Clean ETH handling to avoid the indirection of using a wrapped ether token,
improved UX as a result. 🏋️‍♀️
- Contract is completely trustless and stealing funds would require the exchange
operator to set a rogue exchange and then convince users to send a transaction
approving that exchange to use their funds. 🙅‍♀️
- Low deployment risk: deployment is so simple it is hard to make a mistake on
deployment. This makes it easy too for users to trustlessly verify the code of
the exchange they are interacting with. 🚀
- Math is safe 📓
- Hardware wallet signature support 🙏👍
- Because there is no 'utility token' this exchange could be designed maximizing
UX, and IMO they achieved the best DEX UX I have seen. 🥅⚽️

### Testing suite

#### Critical severity

##### No comprehensive trading tests
- At the moment I reviewed trading logic wasn't thoroughly tested.
- I have been told those were a WIP at the time

#### High severity

##### General low coverage
- No automated coverage metric as part of the CI process
- I recommend a 100% test coverage at least on `Exchange.sol` and `Vault.sol`

##### Tests not run against real nodes
- Even though ganache-core is a full EVM implementation, there have been instances in which
ganache doesn't behave 100% like a real node EVM implementation.
- I recommend running the tests against Geth and/or Parity as part of the CI pipeline.

#### Praise
- Tests are descriptive and easy to follow ✅
- Tests passed at the first try by doing `npm i && npm t` 👍
