const Exchange = artifacts.require('Exchange.sol');
const MockToken = artifacts.require('./mocks/Token.sol');

contract('Organization', function (accounts) {

    let exchange, token;

    beforeEach(async () => {
        token = await MockToken.new();
        exchange = await Exchange.new();
    });

    context('funds', async () => {

        it('should allow depositing of token', async () => {
            let total = 30;
            let using = total / 2;

            await token.mint(accounts[0], total);
            await exchange.deposit(token.address, using, {from: accounts[0]});
            assert.equal(await exchange.balanceOf.call(token.address, accounts[0]), using);
        });

        it('should allow depositing of ether', async () => {
            await exchange.deposit(0x0, 0, {from: accounts[0], value: 10});
            assert.equal(await exchange.balanceOf.call(0x0, accounts[0]), 10);
        });

        it('should allow withdrawing of tokens', async () => {
            let total = 30;
            let using = total / 2;

            await token.mint(accounts[0], total);
            await exchange.deposit(token.address, using, {from: accounts[0]});
            assert.equal(await exchange.balanceOf.call(token.address, accounts[0]), using);

            await exchange.withdraw(token.address, using, {from: accounts[0]});
            assert.equal(await exchange.balanceOf.call(token.address, accounts[0]), 0);
            assert.equal(await token.balanceOf.call(accounts[0]), total);
        });

        it('should allow withdrawing of ether', async () => {
            let using = 15;

            await exchange.deposit(0x0, using, {from: accounts[0], value: using});
            assert.equal(await exchange.balanceOf.call(0x0, accounts[0]), using);

            await exchange.withdraw(0x0, using, {from: accounts[0]});
            assert.equal(await exchange.balanceOf.call(0x0, accounts[0]), 0);
        });
    });
});