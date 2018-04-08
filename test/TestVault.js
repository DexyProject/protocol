const Vault = artifacts.require('vault/Vault.sol');
const MockToken = artifacts.require('./mocks/Token.sol');
const SelfDestructor = artifacts.require('./mocks/SelfDestructor.sol');
const utils = require('./helpers/Utils.js');

contract('Vault', function (accounts) {

    let vault, token;

    beforeEach(async () => {
        token = await MockToken.new();
        vault = await Vault.new();
    });

    describe('funds', async () => {

        it('should revert when directly depositing ether', async () => {
            try {
                await vault.sendTransaction({from: accounts[0], value: 1});
            } catch (error) {
                return utils.ensureException(error);
            }

            assert.fail('depositing ether did not fail');
        });

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

    describe('overflow', async () => {

        it('should allow withdrawing of overflow tokens', async () => {
            await vault.deposit(token.address, 10, {from: accounts[0]});
            await token.transfer(vault.address, 10, {from: accounts[0]});

            let previousBalance = await token.balanceOf(accounts[0]);

            assert.equal(await token.balanceOf(vault.address), 20);
            await vault.withdrawOverflow(token.address, {from: accounts[0]});
            assert.equal(await token.balanceOf(vault.address), 10);

            let balance = await token.balanceOf(accounts[0]);
            assert.equal(balance.toString(18), previousBalance.plus(10).toString(18));
        });

        it('should allow withdrawing of overflow eth', async () => {
            let selfdestruct = await SelfDestructor.new();
            await selfdestruct.sendTransaction({from: accounts[0], value: 10});
            await selfdestruct.destroy(vault.address);
            await vault.deposit(0x0, 10, {from: accounts[0], value: 10});

            assert.equal(await web3.eth.getBalance(vault.address), 20);
            await vault.withdrawOverflow(0x0, {from: accounts[0]});
            assert.equal(await web3.eth.getBalance(vault.address), 10);
        });
    });

    it('should allow setting and unsetting of ERC777 token', async () => {
        await vault.setERC777(token.address, {from: accounts[0]});
        assert.equal(await vault.isERC777(token.address), true);

        await vault.unsetERC777(token.address, {from: accounts[0]});
        assert.equal(await vault.isERC777(token.address), false);
    });

    it('should allow a user to approve and unapprove an exchange', async () => {
        await vault.addSpender(accounts[1]);

        assert.equal(await vault.isApproved(accounts[0], accounts[1]), false);

        await vault.approve(accounts[1], {from: accounts[0]});
        assert.equal(await vault.isApproved(accounts[0], accounts[1]), true);

        await vault.unapprove(accounts[1], {from: accounts[0]});
        assert.equal(await vault.isApproved(accounts[0], accounts[1]), false);
    });

    it('should allow funds to be transferred', async () => {
        let exchange = accounts[2];

        await vault.addSpender(exchange);
        await vault.approve(exchange, {from: accounts[0]});

        let sum = 30;

        await token.mint(accounts[0], sum);
        await vault.deposit(token.address, sum, {from: accounts[0]});
        assert.equal(await vault.balanceOf.call(token.address, accounts[0]), sum);

        await vault.transfer(token.address, accounts[0], accounts[1], sum, {from: exchange});
        assert.equal(await vault.balanceOf.call(token.address, accounts[1]), sum);
    });

    it('should allow adding and removing spender', async () => {
        let exchange = accounts[2];

        await vault.addSpender(exchange);
        assert.equal(true, await vault.isSpender(exchange));

        await vault.removeSpender(exchange);
        assert.equal(false, await vault.isSpender(exchange));
    });
});
