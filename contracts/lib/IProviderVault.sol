// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 Tcash foundation.
pragma solidity ^0.7.0;


/// @title IProviderVault
/// @dev This smart contract manages the distribution of protocol fees.
///     100% of them can be withdrawn to the UserStakingPool contract
///     to reward ERC-20 stakers
abstract contract IProviderVault
{
    address public userStakingPoolAddress;
    address public tokenAddress;

    uint claimedReward;

    event TOKENClaimed(uint amount);
    event SettingsUpdated(uint time);

    /// @dev Sets depdending contract address. All these addresses can be zero.
    /// @param _userStakingPoolAddress The address of the user staking pool.
    function updateSettings(
        address _userStakingPoolAddress
        )
        external
        virtual;

    /// @dev Claims ERC2-TOKEN as staking reward to the IUserStakingPool contract.
    ///      Note that this function can only be called by
    ///      the IUserStakingPool contract.
    ///
    /// @param amount The amount of ERC2-TOKEN to be claimed.
    function claimStakingReward(uint amount) external virtual;

    /// @dev Returns remainingReward The remaining amount of ERC2-TOKEN as staking reward.
    function getRemainingReward()
        public
        view
        virtual
        returns (uint);
}