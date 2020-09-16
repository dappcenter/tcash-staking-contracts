// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 tcash foundation.
pragma solidity ^0.7.0;


/// @title IUserStakingPool
/// @dev This contract manages staked ERC2-TOKEN tokens and their rewards.
///      WARNING: sending tokens directly to this contract will result in all
///      tokens to be lost.
abstract contract IUserStakingPool
{
    uint public constant MIN_CLAIM_DELAY        = 90 days;
    uint public constant MIN_WITHDRAW_DELAY     = 90 days;

    address public tokenAddress;
    address public protocolFeeVaultAddress;

    uint    public numAddresses;

    event ProtocolFeeVaultChanged (address feeVaultAddress);

    event TOKENStaked       (address indexed user,  uint amount);
    event TOKENWithdrawn    (address indexed user,  uint amount);
    event TOKENRewarded     (address indexed user,  uint amount);

    /// @dev Sets a new IProtocolFeeVault address, only callable by the owner.
    /// @param _protocolFeeVaultAddress The new IProtocolFeeVault address.
    function setProtocolFeeVault(address _protocolFeeVaultAddress)
        external
        virtual;

    /// @dev Returns the total number of TOKEN staked.
    function getTotalStaking()
        public
        virtual
        view
        returns (uint);

    /// @dev Returns information related to a specific user.
    /// @param user The user address.
    /// @return withdrawalWaitTime Time in seconds that the user has to wait before any TOKEN can be withdrawn.
    /// @return rewardWaitTime Time in seconds that the user has to wait before any TOKEN reward can be claimed.
    /// @return balance The amount of TOKEN staked or rewarded.
    /// @return pendingReward The amount of TOKEN reward claimable.
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

    /// @dev Users call this function stake certain amount of TOKEN.
    ///      Note that transfering TOKEN directly to this contract will lost those TOKEN!!!
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
