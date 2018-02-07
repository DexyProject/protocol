const SafeMath = artifacts.require("./SafeMath.sol");
const Exchange = artifacts.require("./Exchange.sol");

module.exports = async (deployer) => {

    await deployer.deploy(SafeMath);
    await deployer.deploy(Exchange);
    await deployer.link(SafeMath, [Exchange]);
};
