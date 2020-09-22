const { expectRevert,expectEvent,BN,constants,time } = require('@openzeppelin/test-helpers');
const ProviderVault = artifacts.require('ProviderVault');
const MockERC20 = artifacts.require('MockERC20');
const UserStakingPool = artifacts.require('UserStakingPool');

contract('UserStakingPool', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.tcash = await MockERC20.new( 'TCASH', 'TCASH', 8800000000000000, { from: alice });
    });

    it('should set correct state variables', async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        this.userStakingPool = await UserStakingPool.new(this.tcash.address,1,2, { from: alice });
        await this.userStakingPool.setProviderVault(this.vault.address);
        const tokenAddress = await this.userStakingPool.tokenAddress();
        const providerVaultAddress = await this.userStakingPool.providerVaultAddress();
        const claim_delay = await this.userStakingPool.claim_delay();
        const withdraw_delay = await this.userStakingPool.withdraw_delay();

        assert.equal(tokenAddress.valueOf(), this.tcash.address);
        assert.equal(providerVaultAddress.valueOf(), this.vault.address);
        assert.equal(claim_delay.valueOf(), '1');
        assert.equal(withdraw_delay.valueOf(), '2');
    });

    it('reverts when new UserStakingPool with zero token address', async () => {
        await expectRevert(
           UserStakingPool.new(constants.ZERO_ADDRESS,3,4, { from: alice }),
            'ZERO_ADDRESS',
        );
    });

    it('should work well when setProviderVault zero address', async () => {
        this.userStakingPool = await UserStakingPool.new(this.tcash.address,1,2, { from: alice });
        const receipt = await this.userStakingPool.setProviderVault(constants.ZERO_ADDRESS);
        expectEvent(receipt, 'ProviderVaultChanged', { providerVaultAddress: constants.ZERO_ADDRESS });
        const providerVaultAddress = await this.userStakingPool.providerVaultAddress();
        assert.equal(providerVaultAddress.valueOf(), constants.ZERO_ADDRESS);
    });


    context('stake getTotalStaking getUserStaking test cases', () => {
        beforeEach(async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        this.userStakingPool = await UserStakingPool.new(this.tcash.address,20,30, { from: alice });
        await this.userStakingPool.setProviderVault(this.vault.address, { from: alice });
        await this.vault.updateStakingPool(this.userStakingPool.address, { from: alice });
        await this.tcash.approve(this.vault.address, '1000', { from: alice });
        await this.vault.deposit('1000', { from: alice });
        });

        it('reverts when stake with ZERO_VALUE', async () => {
          await expectRevert(
            this.userStakingPool.stake('0', { from: carol }),
            'ZERO_VALUE',
          );
        });

        it('should be ok stake into pool', async () => {
            await this.tcash.transfer(carol, '2000', { from: alice });
            await this.tcash.approve(this.userStakingPool.address, '2000', { from: carol });
            await this.userStakingPool.stake('2000', { from: carol });
            const numAddresses = await this.userStakingPool.numAddresses();
            const totalStaking = await this.userStakingPool.getTotalStaking();
            assert.equal(numAddresses.valueOf(), '1');
            assert.equal(totalStaking.valueOf(), '2000');
        });

        it('should be ok getUserStaking', async () => {
            await this.tcash.transfer(carol, '2000', { from: alice });
            await this.tcash.approve(this.userStakingPool.address, '2000', { from: carol });
            await this.userStakingPool.stake('2000', { from: carol });
            const {withdrawalWaitTime, rewardWaitTime,balance,pendingReward} = await this.userStakingPool.getUserStaking(carol);

            assert.equal(withdrawalWaitTime.valueOf(), '30');
            assert.equal(rewardWaitTime.valueOf(), '20');
            assert.equal(balance.valueOf(), '2000');
            assert.equal(pendingReward.valueOf(), '0');
        });

        it('should be ok getUserStaking after lock time', async () => {
            await this.tcash.transfer(carol, '2000', { from: alice });
            await this.tcash.approve(this.userStakingPool.address, '2000', { from: carol });
            await this.userStakingPool.stake('2000', { from: carol });
            // after lock time
            await time.increase(40);

            const {withdrawalWaitTime, rewardWaitTime,balance,pendingReward} = await this.userStakingPool.getUserStaking(carol);

            assert.equal(withdrawalWaitTime.valueOf(), '0');
            assert.equal(rewardWaitTime.valueOf(), '0');
            assert.equal(balance.valueOf(), '2000');
            assert.equal(pendingReward.valueOf(), '975');
        });


    });

    context('withdraw claim test cases', () => {
        beforeEach(async () => {
        this.vault = await ProviderVault.new(this.tcash.address, { from: alice });
        this.userStakingPool = await UserStakingPool.new(this.tcash.address,20,30, { from: alice });
        await this.userStakingPool.setProviderVault(this.vault.address, { from: alice });
        await this.vault.updateStakingPool(this.userStakingPool.address, { from: alice });
        await this.tcash.approve(this.vault.address, '1000', { from: alice });
        await this.vault.deposit('1000', { from: alice });
        await this.tcash.transfer(carol, '2000', { from: alice });
        await this.tcash.approve(this.userStakingPool.address, '2000', { from: carol });
        await this.userStakingPool.stake('2000', { from: carol });
        });

        it('reverts when withdraw before lock time', async () => {
          await expectRevert(
            this.userStakingPool.withdraw('1', { from: carol }),
            'NEED_TO_WAIT',
          );
        });

        it('should be ok withdraw from pool', async () => {
            const numAddresses = await this.userStakingPool.numAddresses();
            const totalStaking = await this.userStakingPool.getTotalStaking();
            assert.equal(numAddresses.valueOf(), '1');
            assert.equal(totalStaking.valueOf(), '2000');
            assert.equal((await this.tcash.balanceOf(carol)).valueOf(), '0');
            await time.increase(40);
            await this.userStakingPool.withdraw('2975', { from: carol });
            assert.equal((await this.userStakingPool.numAddresses()).valueOf(), '0');
            assert.equal((await this.userStakingPool.getTotalStaking()).valueOf(), '0');
            assert.equal((await this.tcash.balanceOf(carol)).valueOf(), '2975');
        });

        it('should be ok claim from pool', async () => {
            await time.increase(40);
            const receipt = await this.userStakingPool.claim({ from: carol });
            expectEvent(receipt, 'TOKENRewarded', { user: carol, amount: new BN(975) });
        });

    });


});
