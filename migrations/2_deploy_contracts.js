const SafeMath = artifacts.require("./Libraries/SafeMath.sol");
const Exchange = artifacts.require("./Exchange.sol");
const Vault = artifacts.require("./Vault/Vault.sol");

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(SafeMath);
    await deployer.deploy(Vault);
    await deployer.deploy(Exchange, 0, accounts[0], await Vault.address);
    await deployer.link(SafeMath, [Exchange, Vault]);
};
