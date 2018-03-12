const Vault = artifacts.require('vault/Vault.sol');
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

        it('should allow withdrawing of overflow', async () => {
            await vault.deposit(token.address, 10, {from: accounts[0]});
            await token.transfer(vault.address, 10, {from: accounts[0]});

            let previousBalance = await token.balanceOf(accounts[0]);

            assert.equal(await token.balanceOf(vault.address), 20);
            await vault.withdrawOverflow(token.address, {from: accounts[0]});
            assert.equal(await token.balanceOf(vault.address), 10);

            let balance = await token.balanceOf(accounts[0]);
            assert.equal(balance.toString(18), previousBalance.plus(10).toString(18));
        })
    });

    context('ERC777', async () => {

        it('should allow setting and unsetting of ERC777 token', async () => {
            await vault.setERC777(token.address, {from: accounts[0]});
            assert.equal(await vault.isERC777(token.address), true);

            await vault.unsetERC777(token.address, {from: accounts[0]});
            assert.equal(await vault.isERC777(token.address), false);
        })

    })
});
