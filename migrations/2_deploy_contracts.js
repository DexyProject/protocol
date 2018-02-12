const SafeMath = artifacts.require("./SafeMath.sol");
const Exchange = artifacts.require("./Exchange.sol");

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(SafeMath);
    await deployer.deploy(Exchange, 0, accounts[0]);
    await deployer.link(SafeMath, [Exchange]);
};
