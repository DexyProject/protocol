const SafeMath = artifacts.require("./Libraries/SafeMath.sol");
const Exchange = artifacts.require("./Exchange.sol");
const Vault = artifacts.require("./Vault/Vault.sol");

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(SafeMath);
    await deployer.deploy(Vault, "0x991a1bcb077599290d7305493c9a630c20f8b798");
    await deployer.deploy(Exchange, 0, accounts[0], await Vault.address);
    await deployer.link(SafeMath, [Exchange, Vault]);
};
