pragma solidity ^0.4.18;

import "./FeeInterface.sol";
import "./../Ownership/Ownable.sol";

contract FeeManager is FeeInterface {

    uint256 constant public MAX_FEE = 5000000000000000; // 0.5% ((0.5 / 100) * 10**18)

    mapping (uint => uint) public tiers;
    mapping (address => uint) public level;

    function setTier(uint tier, uint fee) external onlyOwner {
        require(fee <= MAX_FEE);
        tiers[tier] = fee;
    }

    function setUserLevel(address user, uint tier) external onlyOwner {
        level[user] = tier;
    }

    function fees(address user) external view returns (uint) {
        return tiers[level[user]];
    }
}
