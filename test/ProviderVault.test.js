const { expectRevert,expectEvent,BN,constants,time } = require('@openzeppelin/test-helpers');
const ProviderVault = artifacts.require('ProviderVault');
const MockERC20 = artifacts.require('MockERC20');
const UserStakingPool = artifacts.require('UserStakingPool');

contract('ProviderVault', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.tcash = await MockERC20.new( 'TCASH', 'TCASH', 8800000000000000, { from: alice });
    });

    it('should set correct state variables', async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        const tokenAddress = await this.vault.tokenAddress();
        assert.equal(tokenAddress.valueOf(), this.tcash.address);

        this.userStakingPool = await UserStakingPool.new(this.tcash.address,7776000,7776000, { from: alice });
        await this.vault.updateStakingPool(this.userStakingPool.address, { from: alice });
        const userStakingPoolAddress = await this.vault.userStakingPoolAddress();
        assert.equal(userStakingPoolAddress.valueOf(), this.userStakingPool.address);
    });

    it('reverts when new ProviderVault with zero token address', async () => {
        await expectRevert(
           ProviderVault.new(constants.ZERO_ADDRESS, { from: alice }),
            'ZERO_ADDRESS',
        );
    });

    it('reverts when deposit zero tokens ', async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        await this.tcash.approve(this.vault.address, '1000', { from: alice });
        // deposit 0
        await expectRevert(
            this.vault.deposit('0', { from: alice }),
            'ZERO_VALUE',
        );
    });

    it('should work well when deposit 1000 tokens', async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        await this.tcash.approve(this.vault.address, '1000', { from: alice });
        // deposit 1000
        const receipt = await this.vault.deposit('1000', { from: alice });
        expectEvent(receipt, 'TOKENDeposited', { amount: new BN(1000) });
        assert.equal((await this.tcash.balanceOf(this.vault.address)).valueOf(), '1000');
        const remainingReward = await this.vault.getRemainingReward();
        assert.equal(remainingReward.valueOf(), '1000');
    });


    context('withdraw test cases', () => {
        beforeEach(async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        await this.tcash.approve(this.vault.address, '1000', { from: alice });
        await this.vault.deposit('1000', { from: alice });
        });

        it('reverts when withdraw zero tokens ', async () => {
          // withdraw 0
          await expectRevert(
            this.vault.withdraw('0', { from: alice }),
            'ZERO_VALUE',
          );
        });

        it('reverts when withdraw by not owner user', async () => {
          // withdraw 80
          await expectRevert(
            this.vault.withdraw('80', { from: bob }),
            'UNAUTHORIZED',
          );
        });

        it('should allow withdraw some tokens', async () => {
            const receipt = await this.vault.withdraw('80', { from: alice });
            expectEvent(receipt, 'TOKENWithdrawn', { amount: new BN(80) });
            const remainingReward = await this.vault.getRemainingReward();
            assert.equal(remainingReward.valueOf(), '920');
        });

        it('should allow withdraw all tokens', async () => {
            const receipt = await this.vault.withdraw('1000', { from: alice });
            expectEvent(receipt, 'TOKENWithdrawn', { amount: new BN(1000) });
            const remainingReward = await this.vault.getRemainingReward();
            assert.equal(remainingReward.valueOf(), '0');
        });
    });

    context('updateStakingPool test cases', () => {
        beforeEach(async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        this.userStakingPool = await UserStakingPool.new(this.tcash.address,7776000,7776000, { from: alice });
        });

        it('reverts when updateStakingPool with same address', async () => {
          await this.vault.updateStakingPool(this.userStakingPool.address, { from: alice });
          await expectRevert(
            this.vault.updateStakingPool(this.userStakingPool.address, { from: alice }),
            'SAME_ADDRESSES',
          );
        });

        it('reverts when updateStakingPool by not owner user', async () => {
          // withdraw 80
          await expectRevert(
            this.vault.updateStakingPool(this.userStakingPool.address, { from: bob }),
            'UNAUTHORIZED',
          );
        });

        it('should allow updateStakingPool to another pool address', async () => {
            const userStakingPool2 = await UserStakingPool.new(this.tcash.address,7776000,7776000, { from: alice });
            const receipt = await this.vault.updateStakingPool(userStakingPool2.address, { from: alice });
            expectEvent(receipt, 'SettingsUpdated', { });
        });
    });

    context('claimStakingReward test cases', () => {
        beforeEach(async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        this.userStakingPool = await UserStakingPool.new(this.tcash.address,20,20, { from: alice });
        await this.userStakingPool.setProviderVault(this.vault.address, { from: alice });
        await this.vault.updateStakingPool(this.userStakingPool.address, { from: alice });
        await this.tcash.approve(this.vault.address, '1000', { from: alice });
        await this.vault.deposit('1000', { from: alice });
        });

        it('reverts when claimStakingReward zero tokens ', async () => {
          // claimStakingReward 0
          await expectRevert(
            this.vault.claimStakingReward('0', { from: this.userStakingPool.address }),
            'ZERO_VALUE',
          );
        });

        it('reverts when claimStakingReward by not userStakingPoolAddress', async () => {
          await expectRevert(
            this.vault.claimStakingReward('80', { from: alice }),
            'UNAUTHORIZED',
          );
        });

        it('should allow claimStakingReward some tokens', async () => {
            assert.equal((await this.tcash.balanceOf(this.vault.address)).valueOf(), '1000');
            await this.tcash.transfer(carol, '2000', { from: alice });
            await this.tcash.approve(this.userStakingPool.address, '2000', { from: carol });
            await this.userStakingPool.stake('2000', { from: carol });
            await time.increase(20);
            await this.userStakingPool.withdraw('20', { from: carol });
            //1000*20/(20+1)=952
            assert.equal((await this.tcash.balanceOf(this.vault.address)).valueOf(), '48');
            assert.equal((await this.tcash.balanceOf(this.userStakingPool.address)).valueOf(), '2932');
            assert.equal((await this.tcash.balanceOf(carol)).valueOf(), '20');
        });
    });

});
