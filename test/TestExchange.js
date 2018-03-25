const Vault = artifacts.require('vault/Vault.sol');
const Exchange = artifacts.require('Exchange.sol');
const MockToken = artifacts.require('./mocks/Token.sol');
const SelfDestructor = artifacts.require('./mocks/SelfDestructor.sol');
const utils = require('./helpers/Utils.js');
const web3Utils = require('web3-utils');
const ethutil = require('ethereumjs-util');

const schema_hash = '0xa8da5e6ea8c46a0516b3a2e3b010f264e8334214f4b37ff5f2bc8a2dd3f32be1';

contract('Exchange', function (accounts) {

    let vault, exchange;
    let feeAccount;

    beforeEach(async () => {
        feeAccount = accounts[4];

        vault = await Vault.new();
        exchange = await Exchange.new(2500000000000000, feeAccount, vault.address);
        await vault.setExchange(exchange.address)
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
                tokenGive: '0x0000000000000000000000000000000000000000',
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

    describe('trade', async () => {

        let order;
        let data;
        let token;

        beforeEach(async () => {

            token = await MockToken.new();

            order = {
                tokenGet: token.address,
                amountGet: '10000000000000000000000',
                tokenGive: '0x0000000000000000000000000000000000000000',
                amountGive: '1000000000000000000',
                expires: Math.floor((Date.now() / 1000) + 5000),
                nonce: 10,
                user: accounts[0],
                exchange: exchange.address
            };

            data = signOrder(order);
        });

        it('should not allow user to trade own order', async () => {
            try {
                await exchange.trade(data.addresses, data.values, 10, data.sig, {from: accounts[0]});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('trade did not fail');
        });

        it('should not allow user to trade order without enough balance', async () => {
            try {
                await exchange.trade(data.addresses, data.values, 10, data.sig, {from: accounts[1]});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('trade did not fail');
        });

        it('should transfer fees correctly on trade', async () => {
            await vault.deposit(0x0, order.amountGive, {from: accounts[0], value: order.amountGive});
            await vault.approve(exchange.address);

            await token.mint(accounts[1], order.amountGet);
            await vault.deposit(token.address, order.amountGet, {from: accounts[1]});
            await vault.approve(exchange.address, {from: accounts[1]});

            await exchange.trade(data.addresses, data.values, order.amountGet, data.sig, {from: accounts[1]});

            assert.equal((await vault.balanceOf(0x0, feeAccount)).toString(), '2500000000000000');
            assert.equal((await exchange.filled.call(accounts[0], data.hash)).toString(10), '10000000000000000000000')
        });

        it('should trade on chain created order correctly', async () => {
            await vault.deposit(0x0, order.amountGive, {from: accounts[0], value: order.amountGive});
            await vault.approve(exchange.address);

            await exchange.order([order.tokenGive, order.tokenGet], data.values, {from: accounts[0]});

            await token.mint(accounts[1], order.amountGet);
            await vault.deposit(token.address, order.amountGet, {from: accounts[1]});
            await vault.approve(exchange.address, {from: accounts[1]});

            await exchange.trade(data.addresses, data.values, order.amountGet, '0x0', {from: accounts[1]});

            assert.equal((await vault.balanceOf(0x0, feeAccount)).toString(), '2500000000000000');
            assert.equal((await exchange.filled.call(accounts[0], data.hash)).toString(10), '10000000000000000000000')
        });
    });

    describe('on chain orders', async () => {

        let order;
        let token;
        let data;

        beforeEach(async () => {
            token = await MockToken.new();

            order = {
                tokenGet: token.address,
                amountGet: '10',
                tokenGive: '0x0000000000000000000000000000000000000000',
                amountGive: '100',
                expires: Math.floor((Date.now() / 1000) + 5000),
                nonce: 10,
                user: accounts[0],
                exchange: exchange.address
            };

            data = {
                addresses: [order.tokenGive, order.tokenGet],
                values: [order.amountGive, order.amountGet, order.expires, order.nonce]
            }
        });

        it('should fail to order when vault has not been approved', async () => {
            try {
                await exchange.order(data.addresses, data.values, {from: accounts[0]});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('ordering did not fail');
        });

        it('should fail to order when user does not have enough balance', async () => {
            await vault.approve(exchange.address);

            try {
                await exchange.order(data.addresses, data.values, {from: accounts[0]});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('ordering did not fail');
        });

        it('should allow ordering on chain', async () => {
            await vault.approve(exchange.address);
            await vault.deposit(0x0, order.amountGet, {from: accounts[0], value: order.amountGive});

            let result = await exchange.order(data.addresses, data.values, {from: accounts[0]});

            let log = result.logs[0].args;
            assert.equal(accounts[0], log.user);
            assert.equal(order.tokenGive, log.tokenGive);
            assert.equal(order.tokenGet, log.tokenGet);
            assert.equal(order.amountGet, log.amountGet.toString(10));
            assert.equal(order.amountGive, log.amountGive.toString(10));
            assert.equal(order.expires, log.expires);
            assert.equal(order.nonce, log.nonce);

            let hashed = hashOrder(order);
            assert.equal(await exchange.isOrdered(accounts[0], hashed.hash), true);
        });

        it('should not allow duplicate orders', async () => {
            await vault.approve(exchange.address);
            await vault.deposit(0x0, order.amountGet, {from: accounts[0], value: order.amountGive});

            await exchange.order(data.addresses, data.values, {from: accounts[0]});

            try {
                await exchange.order(data.addresses, data.values, {from: accounts[0]});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('ordering did not fail');
        });
    });

    describe('canTrade', async () => {

        let token;
        let order;
        let data;

        beforeEach(async () => {

            token = await MockToken.new();

            order = {
                tokenGet: token.address,
                amountGet: '10',
                tokenGive: '0x0000000000000000000000000000000000000000',
                amountGive: '100',
                expires: Math.floor((Date.now() / 1000) + 5000),
                nonce: 10,
                user: accounts[0],
                exchange: exchange.address
            };

            data = signOrder(order);
        });

        it('should return false when order is signed by different user', async () => {
            data.addresses[0] = accounts[1];
            assert.equal(await exchange.canTrade(data.addresses, data.values, 10, data.sig), false);
        });

        it('should return false when order is cancelled', async () => {
            await exchange.cancel(data.addresses, data.values);
            assert.equal(await exchange.canTrade(data.addresses, data.values, 10, data.sig), false);
        });

        it('should return false when users do not have enough funds', async () => {
            assert.equal(await exchange.canTrade(data.addresses, data.values, 10, data.sig), false);
        });

        it('should return false when vault has not been approved', async () => {
            await token.mint(accounts[0], order.amountGet);
            await vault.deposit(token.address, order.amountGet, {from: accounts[0]});

            assert.equal(await exchange.canTrade(data.addresses, data.values, 10, data.sig), false);
        });

        it('should return false when vault has not been approved', async () => {
            await vault.deposit(0x0, order.amountGet, {from: accounts[0], value: order.amountGive});
            assert.equal(await exchange.canTrade(data.addresses, data.values, order.amountGet, data.sig), false);
        });

        it('should return false when order has been expired', async () => {
            order = {
                tokenGet: token.address,
                amountGet: '10',
                tokenGive: '0x0000000000000000000000000000000000000000',
                amountGive: '100',
                expires: Math.floor((Date.now() / 1000) - 5000),
                nonce: 10,
                user: accounts[0],
                exchange: exchange.address
            };

            data = signOrder(order);

            await vault.deposit(0x0, order.amountGet, {from: accounts[0], value: order.amountGive});
            await vault.approve(exchange.address);

            assert.equal(await exchange.canTrade(data.addresses, data.values, 1, data.sig), false);
        });

        it('should return false when order get amount is too large', async () => {
            order = {
                tokenGet: token.address,
                amountGet: '10',
                tokenGive: '0x0000000000000000000000000000000000000000',
                amountGive: '100',
                expires: Math.floor((Date.now() / 1000) + 5000),
                nonce: 10,
                user: accounts[0],
                exchange: exchange.address
            };

            data = signOrder(order);

            await vault.deposit(0x0, order.amountGive, {from: accounts[0], value: order.amountGive});
            await vault.approve(exchange.address);

            await token.mint(accounts[1], order.amountGet);
            await vault.deposit(token.address, order.amountGet, {from: accounts[1]});
            await vault.approve(exchange.address, {from: accounts[1]});

            await exchange.trade(data.addresses, data.values, order.amountGet / 2, data.sig, {from: accounts[1]});

            assert.equal(await exchange.canTrade(data.addresses, data.values, order.amountGet, data.sig), false);
        });
    });

    describe('token overflow', async () => {

        it('should allow withdrawing of overflow tokens', async () => {

            let token = await MockToken.new();

            let amount = 10;
            await token.mint(accounts[1], amount);
            await token.transfer(exchange.address, amount, {from: accounts[1]});

            await exchange.withdraw(token.address, amount / 2, {from: accounts[0]});
            assert.equal((await token.balanceOf(accounts[0])).toString(10), amount / 2);
        });

        it('should allow withdrawing of overflow eth', async () => {
            let selfdestruct = await SelfDestructor.new();

            let amount = 10;
            await selfdestruct.sendTransaction({from: accounts[0], value: amount});
            await selfdestruct.destroy(exchange.address);

            assert.equal(await web3.eth.getBalance(exchange.address), amount);
            await exchange.withdraw(0x0, amount, {from: accounts[0]});
            assert.equal((await web3.eth.getBalance(exchange.address)).toString(10), 0);
        });
    });
});

function signOrder(order) {
    let hashed = hashOrder(order);

    let sig = web3.eth.sign(order.user, hashed.hash).slice(2);
    let r = ethutil.toBuffer('0x' + sig.substring(0, 64));
    let s = ethutil.toBuffer('0x' + sig.substring(64, 128));
    let v = parseInt(sig.substring(128, 130), 16) + 27;

    let mode = ethutil.toBuffer(1);
    v = ethutil.toBuffer(v);

    let signature = '0x' + Buffer.concat([mode, v, r, s]).toString('hex');

    return {addresses: hashed.addresses, values: hashed.values, sig: signature, hash: hashed.hash};
}

function hashOrder(order) {
    let addresses = [order.user, order.tokenGive, order.tokenGet];
    let values = [order.amountGive, order.amountGet, order.expires, order.nonce];

    let valuesHash = web3Utils.soliditySha3.apply(null, Object.entries(order).map(function (x) {
        return x[1]
    }));

    let hash = web3Utils.soliditySha3(schema_hash, valuesHash);

    return {hash: hash, addresses: addresses, values: values}
}
