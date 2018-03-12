const Vault = artifacts.require('vault/Vault.sol');
const Exchange = artifacts.require('Exchange.sol');
const utils = require('./helpers/Utils.js');

contract('Exchange', function (accounts) {

    let vault, exchange;

    beforeEach(async () => {
        vault = await Vault.new();
        exchange = await Exchange.new(2500000000000000, accounts[2], vault.address);
    });

    it('should revert when depositing ether', async () => {
        try {
            await exchange.sendTransaction({from: accounts[0], value: 1});
        } catch (error) {
            return utils.ensureException(error);
        }

        assert.fail('depositing ether did not fail');
    });

});