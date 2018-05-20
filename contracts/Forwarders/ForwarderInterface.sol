pragma solidity ^0.4.18;

interface ForwarderInterface {

    /// @dev Takes order on behalf of a user.
    /// @param addresses Array of trade's maker, makerToken and takerToken.
    /// @param values Array of trade's makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @param sig Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    /// @param nonce Random taker nonce.
    /// @param takerSig Taker signature, taker address MUST be derived from this signature.
    function trade(
        address[3] addresses,
        uint[4] values,
        bytes sig,
        uint maxFillAmount,
        uint nonce,
        bytes takerSig
    ) external;

    /// @dev Returns if a user is permitted to take orders.
    /// @param user Address of the user
    /// @return Bool whether user can trade.
    function isPermitted(address user) public view returns (bool);

}
