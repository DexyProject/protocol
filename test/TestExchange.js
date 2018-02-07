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
            await token.mint(accounts[0], 30);
            await exchange.deposit(token.address, 15, {from: accounts[0]});
            assert.equal(await exchange.balanceOf.call(token.address, accounts[0]), 15);
        });

        it('should allow depositing of ether', async () => {
            await exchange.deposit(0x0, 15, {from: accounts[0], value: 10});
            assert.equal(await exchange.balanceOf.call(0x0, accounts[0]), 10);
        });

    });
});