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
import "./lib/IProviderVault.sol";

/// @title An Implementation of IProviderVault.
contract ProviderVault is Claimable, ReentrancyGuard, IProviderVault
{
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;

    constructor(address _tokenAddress)
        Claimable()
    {
        require(_tokenAddress != address(0), "ZERO_ADDRESS");
        tokenAddress = _tokenAddress;
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
        tokenAddress.safeTransferAndVerify(userStakingPoolAddress, amount);
        claimedReward = claimedReward.add(amount);
        emit TOKENClaimed(amount);
    }

    function getRemainingReward()
        public
        view
        override
        returns (uint)
    {
        return ERC20(tokenAddress).balanceOf(address(this));
    }
}
