const Vault = artifacts.require('Vault.sol');
const MockToken = artifacts.require('./mocks/Token.sol');

contract('Vault', function (accounts) {

    let vault, token;

    beforeEach(async () => {
        token = await MockToken.new();
        vault = await Vault.new();
    });

    context('funds', async () => {

        it('should allow depositing of token', async () => {
            let total = 30;
            let using = total / 2;

            await token.mint(accounts[0], total);
            await vault.deposit(token.address, using, {from: accounts[0]});
            assert.equal(await vault.balanceOf.call(token.address, accounts[0]), using);
        });

        it('should allow depositing of ether', async () => {
            await vault.deposit(0x0, 0, {from: accounts[0], value: 10});
            assert.equal(await vault.balanceOf.call(0x0, accounts[0]), 10);
        });

        it('should allow withdrawing of tokens', async () => {
            let total = 30;
            let using = total / 2;

            await token.mint(accounts[0], total);
            await vault.deposit(token.address, using, {from: accounts[0]});
            assert.equal(await vault.balanceOf.call(token.address, accounts[0]), using);

            await vault.withdraw(token.address, using, {from: accounts[0]});
            assert.equal(await vault.balanceOf.call(token.address, accounts[0]), 0);
            assert.equal(await token.balanceOf.call(accounts[0]), total);
        });

        it('should allow withdrawing of ether', async () => {
            let using = 15;

            await vault.deposit(0x0, using, {from: accounts[0], value: using});
            assert.equal(await vault.balanceOf.call(0x0, accounts[0]), using);

            await vault.withdraw(0x0, using, {from: accounts[0]});
            assert.equal(await vault.balanceOf.call(0x0, accounts[0]), 0);
        });
    });
});