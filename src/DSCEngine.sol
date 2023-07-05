//SPDX-License-Identifier:MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Decentralized Stable Coin Engine
/// @author Jordan Greer

// The system is designed to be as minimal as possible, ensuring the tokens maintain a 1 token == $1 peg.

// This stablecoin has the following properties:
// - Exogenous Collateral
// - Dollar Pegged
// - Algorithmically Stable

// It is similar to DAI, but with no governance, no fees, and exclusively backed by WETH and WBTC.

// Our DSC system should always be over-collateralized.  The invariant is all collateral > all DSC.

/// @notice This contract is the core of the DSC System. It handles all the logic for minting
// and redeeming DSC, as well as depositing & withdrawing collateral.

/// @notice This contract is VERY loosely based on the MakerDAO system.

contract DSCEngine is ReentrancyGuard {
    //////////
    //Errors//
    //////////

    error DSCEngine__MustBeMoreThanZero();
    error DSCEngine__TokenAndPriceFeedLengthMismatch();
    error DSCEngine__PriceFeedNotAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorIsBroken(uint256 healthFactor);
    error DSCEngine__MintFailed();

    ///////////////////
    //State Variables//
    ///////////////////
    uint256 private constant MIN_HEALTH_FACTOR = 1; //The minimum health factor allowed.

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; //The precision needed for the price feed.
    uint256 private constant PRECISION = 1e18; //The precision needed for the return price.

    uint256 private constant LIQUIDATION_THRESHOLD = 50; //The liquidation threshold - 200% overcollateralized.
    uint256 private constant LIQUIDATION_PRECISION = 100; // The precision needed for the liquidation threshold.

    mapping(address token => address priceFeed) private s_priceFeeds; //Token to the price feed.
    mapping(address user => mapping(address token => uint256 amount))
        private s_collateralDeposited; //The amount of collateral deposited by a user.

    mapping(address user => uint256 amountDscMinted) private s_DSCMinted; //The amount of DSC minted by a user.

    address[] private s_collateralTokens; //The collateral tokens.

    DecentralizedStableCoin private immutable i_dsc; //The DSC token.

    ///////////
    //Events//
    //////////

    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    //////////////
    //Moddifiers//
    //////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedPriceFeed(address priceFeed) {
        if (s_priceFeeds[priceFeed] == address(0)) {
            revert DSCEngine__PriceFeedNotAllowed();
        }
        _;
    }

    /////////////
    //Functions//
    /////////////

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        //Check if the token and price feed arrays are the same length.
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAndPriceFeedLengthMismatch();
        }

        //Set USD Price feeds for collateral tokens.

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        //Set DSC token.
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ///////////////////////
    //External Functions///
    ///////////////////////

    function getDscAddress() external view returns (address) {
        return address(i_dsc);
    }

    function depositCollateralAndMintDSC() external {}

    /// @notice follows CEI
    /// @param tokenCollateralAddress The address of the collateral token to deposit.
    /// @param amountCollateral The amount of collateral to deposit.

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedPriceFeed(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );

        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );

        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    /// @notice follows CEI
    /// @param amountToMint The amount of DSC to mint.
    /// @notice Must have more collateral value than threshold.

    function mintDsc(
        uint256 amountToMint
    ) external moreThanZero(amountToMint) nonReentrant {
        // Update account of DSC minted.
        s_DSCMinted[msg.sender] += amountToMint;
        // Check health factor with updated DSC minted.
        _revertIfHealthFactorIsBroken(msg.sender);
        // Mint DSC.
        bool minted = i_dsc.mint(msg.sender, amountToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ////////////////////
    //PUBLIC FUNCTIONS//
    ////////////////////

    ///@dev Returns the amount of collateral deposited by a user.

    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        //1. Get total collateral value
        //2. Return total collateral value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeeds[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // If 1 ETH = $1000, the returned price will be 100000000000.
        // The returned price from Chainlink will be 1000 * 1e8.
        // We need to make sure we return in proper precision.

        //          100000000000    *    1e10            *     1     /   1e18
        return
            ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION; // (1000 * 1e8 * (1e10)) * 1000 * 1e18;
    }

    ///////////////////////////////////////
    //Private and Internal View Functions//
    ///////////////////////////////////////

    ///@dev fuction for retrieving account information for a user

    function _getAccountInformation(
        address user
    )
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        //1. Get total DSC minted
        //2. Get total collateral value
        //3. Return both

        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    ///@dev Returns how close to liquidation a user is

    function _healthFactor(address user) private view returns (uint256) {
        //To determine health factor we need DSC minted and collateral value.

        (
            uint256 totalDscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInformation(user);

        //Example Math:
        // Having $1000 in ETH / 100 DSC - Checking for 200% collateralization
        // 1000 * 50 / 100 = (500 / 100) = 5 > 1
        // Collateral in USD (1000) * Threshold(50) =  50,000
        // 50,000 / DSC Minted (100) = 500
        //
        // Essentially dividing by two here, but multiplying by a fraction (1/2) to get precision.

        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        //Putting adjusted collateral in preceion, then dividing by DSC minted to determine health factor.
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    ///@dev Revert function if Health Factor for user is in good standing

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 healthFactor = _healthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsBroken(healthFactor);
        }
    }
}
