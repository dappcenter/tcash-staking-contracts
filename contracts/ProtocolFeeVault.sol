// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 tcash foundation.
pragma solidity ^0.7.0;

import "./lib/ERC20.sol";
import "./lib/AddressUtil.sol";
import "./lib/BurnableERC20.sol";
import "./lib/Ownable.sol";
import "./lib/Claimable.sol";
import "./lib/ERC20SafeTransfer.sol";
import "./lib/MathUint.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/IProtocolFeeVault.sol";

/// @title An Implementation of IProtocolFeeVault.
contract ProtocolFeeVault is Claimable, ReentrancyGuard, IProtocolFeeVault
{
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;

    constructor(address _lrcAddress)
        Claimable()
    {
        require(_lrcAddress != address(0), "ZERO_ADDRESS");
        lrcAddress = _lrcAddress;
    }

    function updateSettings(
        address _userStakingPoolAddress
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        require(
            userStakingPoolAddress != _userStakingPoolAddress,
            "SAME_ADDRESSES"
        );
        userStakingPoolAddress = _userStakingPoolAddress;
        emit SettingsUpdated(block.timestamp);
    }

    function claimStakingReward(
        uint amount
        )
        external
        override
        nonReentrant
    {
        require(amount > 0, "ZERO_VALUE");
        require(msg.sender == userStakingPoolAddress, "UNAUTHORIZED");
        lrcAddress.safeTransferAndVerify(userStakingPoolAddress, amount);
        claimedReward = claimedReward.add(amount);
        emit LRCClaimed(amount);
    }

    function getProtocolFeeStats()
        public
        view
        override
        returns (uint)
    {
        return ERC20(lrcAddress).balanceOf(address(this));
    }
}
