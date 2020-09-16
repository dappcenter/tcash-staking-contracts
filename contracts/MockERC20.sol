// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 tcash foundation.
pragma solidity ^0.7.0;


import "./lib/ERC20Token.sol";


contract MockERC20 is ERC20Token {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    )  ERC20Token(name, symbol,18,supply,msg.sender) {
    }
}
