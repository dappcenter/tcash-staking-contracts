// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 tcash foundation.
pragma solidity ^0.7.0;


/// @title IUserStakingPool
/// @dev This contract manages staked ERC20-TOKEN tokens and their rewards.
///      WARNING: sending tokens directly to this contract will result in all
///      tokens to be lost.
abstract contract IUserStakingPool
{

    address public tokenAddress;
    address public protocolFeeVaultAddress;

    uint    public numAddresses;

    event ProviderVaultChanged (address feeVaultAddress);

    event TOKENStaked       (address indexed user,  uint amount);
    event TOKENWithdrawn    (address indexed user,  uint amount);
    event TOKENRewarded     (address indexed user,  uint amount);

    /// @dev Sets a new IProviderVault address, only callable by the owner.
    /// @param _protocolFeeVaultAddress The new IProviderVault address.
    function setProviderVault(address _protocolFeeVaultAddress)
        external
        virtual;

    /// @dev Returns the total number of token staked.
    function getTotalStaking()
        public
        virtual
        view
        returns (uint);

    /// @dev Returns information related to a specific user.
    /// @param user The user address.
    /// @return withdrawalWaitTime Time in seconds that the user has to wait before any token can be withdrawn.
    /// @return rewardWaitTime Time in seconds that the user has to wait before any token reward can be claimed.
    /// @return balance The amount of token staked or rewarded.
    /// @return pendingReward The amount of token reward claimable.
    function getUserStaking(address user)
        public
        virtual
        view
        returns (
            uint withdrawalWaitTime,
            uint rewardWaitTime,
            uint balance,
            uint pendingReward
        );

    /// @dev Users call this function stake certain amount of token.
    ///      Note that transfering token directly to this contract will lost those token!!!
    /// @param amount The amount of TOKEN to stake.
    function stake(uint amount)
        external
        virtual;

    /// @dev Users call this funciton to withdraw staked TOKEN.
    /// @param amount The amount of TOKEN to withdraw.
    function withdraw(uint amount)
        external
        virtual;

    /// @dev Users call this funciton to claim all his/her TOKEN reward. The claimed TOKEN
    ///      will be staked again automatically.
    /// @param claimedAmount The amount of TOKEN claimed.
    function claim()
        external
        virtual
        returns (uint claimedAmount);
}
