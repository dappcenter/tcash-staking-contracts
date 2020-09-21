// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 tcash foundation.

pragma solidity ^0.7.0;

import "./lib/IProviderVault.sol";
import "./lib/Claimable.sol";
import "./lib/ERC20.sol";
import "./lib/ERC20SafeTransfer.sol";
import "./lib/MathUint.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/IUserStakingPool.sol";


/// @title An Implementation of IUserStakingPool.
contract UserStakingPool is Claimable, ReentrancyGuard, IUserStakingPool
{
    using ERC20SafeTransfer for address;
    using MathUint          for uint;

    struct Staking {
        uint   balance;        // Total amount of TOKEN staked or rewarded
        uint64 depositedAt;
        uint64 claimedAt;      // timestamp from which more points will be accumulated
    }

    Staking public total;
    mapping (address => Staking) public stakings;
    uint public claim_delay;
    uint public withdraw_delay;

    constructor(address _tokenAddress,
        uint _claim_delay,
        uint _withdraw_delay)
        Claimable()
    {
        require(_tokenAddress != address(0), "ZERO_ADDRESS");
        tokenAddress = _tokenAddress;
        claim_delay = _claim_delay;
        withdraw_delay = _withdraw_delay;
    }

    function setProviderVault(address _providerVaultAddress)
        external
        override
        nonReentrant
        onlyOwner
    {
        // Allow zero-address
        providerVaultAddress = _providerVaultAddress;
        emit ProviderVaultChanged(providerVaultAddress);
    }

    function getTotalStaking()
        public
        override
        view
        returns (uint)
    {
        return total.balance;
    }

    function getUserStaking(address user)
        public
        override
        view
        returns (
            uint withdrawalWaitTime,
            uint rewardWaitTime,
            uint balance,
            uint pendingReward
        )
    {
        withdrawalWaitTime = getUserWithdrawalWaitTime(user);
        rewardWaitTime = getUserClaimWaitTime(user);
        balance = stakings[user].balance;
        (, , pendingReward) = getUserPendingReward(user);
    }

    function stake(uint amount)
        external
        override
        nonReentrant
    {
        require(amount > 0, "ZERO_VALUE");

        // Lets trandfer TOKEN first.
        tokenAddress.safeTransferFromAndVerify(msg.sender, address(this), amount);

        Staking storage user = stakings[msg.sender];

        if (user.balance == 0) {
            numAddresses += 1;
        }

        // update user staking
        uint balance = user.balance.add(amount);

        user.depositedAt = uint64(
            user.balance
                .mul(user.depositedAt)
                .add(amount.mul(block.timestamp)) / balance
        );

        user.claimedAt = uint64(
            user.balance
                .mul(user.claimedAt)
                .add(amount.mul(block.timestamp)) / balance
        );

        user.balance = balance;

        // update total staking
        balance = total.balance.add(amount);

        total.claimedAt = uint64(
            total.balance
                .mul(total.claimedAt)
                .add(amount.mul(block.timestamp)) / balance
        );

        total.balance = balance;

        emit TOKENStaked(msg.sender, amount);
    }

    function withdraw(uint amount)
        external
        override
        nonReentrant
    {
        require(getUserWithdrawalWaitTime(msg.sender) == 0, "NEED_TO_WAIT");

        // automatical claim when possible
        if (providerVaultAddress != address(0) &&
            getUserClaimWaitTime(msg.sender) == 0) {
            claimReward();
        }

        Staking storage user = stakings[msg.sender];

        uint _amount = (amount == 0 || amount > user.balance) ? user.balance : amount;
        require(_amount > 0, "ZERO_BALANCE");

        total.balance = total.balance.sub(_amount);
        user.balance = user.balance.sub(_amount);

        if (user.balance == 0) {
            numAddresses -= 1;
            delete stakings[msg.sender];
        }

        // transfer TOKEN to user
        tokenAddress.safeTransferAndVerify(msg.sender, _amount);

        emit TOKENWithdrawn(msg.sender, _amount);
    }

    function claim()
        external
        override
        nonReentrant
        returns (uint claimedAmount)
    {
        return claimReward();
    }

    // -- Private Function --
    function claimReward()
        private
        returns (uint claimedAmount)
    {
        require(providerVaultAddress != address(0), "ZERO_ADDRESS");
        require(getUserClaimWaitTime(msg.sender) == 0, "NEED_TO_WAIT");

        uint totalPoints;
        uint userPoints;

        (totalPoints, userPoints, claimedAmount) = getUserPendingReward(msg.sender);

        if (claimedAmount > 0) {
            IProviderVault(providerVaultAddress).claimStakingReward(claimedAmount);

            total.balance = total.balance.add(claimedAmount);

            total.claimedAt = uint64(
                block.timestamp.sub(totalPoints.sub(userPoints) / total.balance)
            );

            Staking storage user = stakings[msg.sender];
            user.balance = user.balance.add(claimedAmount);
            user.claimedAt = uint64(block.timestamp);
        }
        emit TOKENRewarded(msg.sender, claimedAmount);
    }

    function getUserWithdrawalWaitTime(address user)
        private
        view
        returns (uint)
    {
        uint depositedAt = stakings[user].depositedAt;
        if (depositedAt == 0) {
            return withdraw_delay;
        } else {
            uint time = depositedAt + withdraw_delay;
            return (time <= block.timestamp) ? 0 : time.sub(block.timestamp);
        }
    }

    function getUserClaimWaitTime(address user)
        private
        view
        returns (uint)
    {
        uint claimedAt = stakings[user].claimedAt;
        if (claimedAt == 0) {
            return claim_delay;
        } else {
            uint time = stakings[user].claimedAt + claim_delay;
            return (time <= block.timestamp) ? 0 : time.sub(block.timestamp);
        }
    }

    function getUserPendingReward(address user)
        private
        view
        returns (
            uint totalPoints,
            uint userPoints,
            uint pendingReward
        )
    {
        Staking storage staking = stakings[user];

        // We add 1 to the time to make totalPoints slightly bigger
        totalPoints = total.balance.mul(block.timestamp.sub(total.claimedAt).add(1));
        userPoints = staking.balance.mul(block.timestamp.sub(staking.claimedAt));

        // Because of the math calculation, this is possible.
        if (totalPoints < userPoints) {
            userPoints = totalPoints;
        }

        if (providerVaultAddress != address(0) &&
            totalPoints != 0 &&
            userPoints != 0) {
             pendingReward = IProviderVault(
                providerVaultAddress
            ).getRemainingReward();
            pendingReward = pendingReward.mul(userPoints) / totalPoints;
        }
    }
}
