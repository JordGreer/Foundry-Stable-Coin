//SPDX-License-Identifier:MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
pragma solidity ^0.8.20;

/*
@title Decentralized Stable Coin Engine
@author Jordan Greer

The system is designed to be as minimal as possible, ensuring the tokens maintain a 1 token == $1 peg.

This stablecoin has the following properties:
- Exogenous Collateral
- Dollar Pegged
- Algorithmically Stable

It is similar to DAI, but with no governance, no fees, and exclusively backed by WETH and WBTC.
*/

contract DSCEngine {

}
