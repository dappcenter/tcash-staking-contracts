// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 Tcash foundation.
pragma solidity ^0.7.0;


/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
abstract contract ERC20
{
    function totalSupply()
        public
        virtual
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        virtual
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        virtual
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        virtual
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        virtual
        returns (bool);
}
