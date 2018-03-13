const Vault = artifacts.require('vault/Vault.sol');
const Exchange = artifacts.require('Exchange.sol');
const utils = require('./helpers/Utils.js');

contract('Exchange', function (accounts) {

    const schema_hash = '0xa8da5e6ea8c46a0516b3a2e3b010f264e8334214f4b37ff5f2bc8a2dd3f32be1';

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

    describe('cancel', async () => {

        let order, addresses, values;

        beforeEach(async () => {
            order = {
                tokenGet: '0xc5427f201fcbc3f7ee175c22e0096078c6f584c4',
                amountGet: '10',
                tokenGive: '0x000000000000000000000000000000000000000',
                amountGive: '100',
                expires: Math.floor((Date.now() / 1000) + 5000),
                nonce: 10,
                user: accounts[0],
                exchange: exchange.address
            };

            addresses = [order.user, order.tokenGive, order.tokenGet];
            values = [order.amountGive, order.amountGet, order.expires, order.nonce];
        });


        it('should allow user to cancel own order', async () => {
            let result = await exchange.cancel(addresses, values);
            assert.equal(result['logs'][0]['event'], 'Cancelled');
        });


        it('should prevent user to cancel other users order', async () => {
            try {
                await exchange.cancel(addresses, values, {from: accounts[1]});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('cancelling did not fail');
        });
    });

});