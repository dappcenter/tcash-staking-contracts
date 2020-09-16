// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 Tcash foundation.
pragma solidity ^0.7.0;


/// @title IProtocolFeeVault
/// @dev This smart contract manages the distribution of protocol fees.
///     100% of them can be withdrawn to the UserStakingPool contract
///     to reward LRC stakers
abstract contract IProtocolFeeVault
{
    address public userStakingPoolAddress;
    address public lrcAddress;

    uint claimedReward;

    event LRCClaimed(uint amount);
    event SettingsUpdated(uint time);

    /// @dev Sets depdending contract address. All these addresses can be zero.
    /// @param _userStakingPoolAddress The address of the user staking pool.
    function updateSettings(
        address _userStakingPoolAddress
        )
        external
        virtual;

    /// @dev Claims LRC as staking reward to the IUserStakingPool contract.
    ///      Note that this function can only be called by
    ///      the IUserStakingPool contract.
    ///
    /// @param amount The amount of LRC to be claimed.
    function claimStakingReward(uint amount) external virtual;

    /// @dev Returns some global stats regarding fees.
    /// @return remainingReward The remaining amount of LRC as staking reward.
    function getProtocolFeeStats()
        public
        view
        virtual
        returns (uint);
}