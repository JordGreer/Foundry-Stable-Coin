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

Our DSC system should always be over-collateralized.  The invariant is all collateral > all DSC.

@notice This contract is the core of the DSC System. It handles all the logic for minting
and redeeming DSC, as well as depositing & withdrawing collateral.

@notice This contract is VERY loosely based on the MakerDAO system.

*/

contract DSCEngine {
    function depositCollateralAndMintDSC() external {}

    function depositCollateral() external {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
